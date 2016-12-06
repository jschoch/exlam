defmodule Exlam do
end

defmodule Mix.Tasks.Exlam.Hello do
  use Mix.Task
  def run(_args) do
    Mix.shell.info "sup"
  end
end

defmodule Mix.Tasks.Exlam.Init do
  use Mix.Task
  alias Mix.Exlam.{Utils }

  @deploy_stage_dir "deploy"
  @defaults %{
    tmp_dir: "./#{@deploy_stage_dir}/burn",
    sam_mem_size: 1024,
    sam_timeout: 30,
    sam_role_arn: "INCOMPLETE",
    sam_s3_bucket: "INCOMPLETE",
    sam_stack_name: "INCOMPLETE",
    http_port: 8086,
    erts_version: :erlang.system_info(:version)
    }
  @shortdoc "initilize exlam deploy"

  def run(args) do
    Mix.Task.run("loadpaths", [])
    Mix.Task.run("compile", [])
    #Logger.configure(:debug)
    opts = parse_args(args)
    File.mkdir_p!(@deploy_stage_dir)

    bindings = genConfig()
    genSam(bindings)
    genIndex(bindings)
    :ok
  end
  def genConfig(path \\Path.join(@deploy_stage_dir, "config.exs")) do
    project_config = Mix.Project.config |> Enum.into %{} |> Map.merge @defaults
    Mix.shell.info "generating config"
    {:ok, config} = Utils.template(:example_config, [b: project_config])
    File.write!(Path.join(@deploy_stage_dir, "config.exs"), config)
    project_config
  end
  def genSam(config) do
    Mix.shell.info "Create SAM file"
    {:ok, sam} = Utils.template(:example_sam, [b: config])
    File.write!(Path.join(@deploy_stage_dir, "deploy.yaml"), sam)
    sam
  end
  defp parse_args(argv) do
    #{overrides, _} = OptionParser.parse!(argv,
      #strict: [no_doc: :boolean,
               #release_per_app: :boolean,
               #name: :string])
    overrides = %{}
    Map.merge(@defaults, overrides)
  end
  def genIndex(config) do
    {:ok, index} = Utils.template(:example_index, [b: config])
    File.write!(Path.join(@deploy_stage_dir, "index.js"), index)
  end
end

defmodule Mix.Tasks.Exlam.Uf do
  @deploy_stage_dir "deploy"
  alias Mix.Exlam.{Utils }
  def run(args \\["-cf"]) do
    Mix.Task.run("loadpaths", []) 
    config = Mix.Tasks.Exlam.Package.makeConfig
    Utils.qcmd "aws lambda update-function-code  --function-name #{config.app} --zip-file fileb://./lambda_deploy.zip --publish"
  end
end

defmodule Mix.Tasks.Exlam.Deploy do
  @deploy_stage_dir "deploy"
  alias Mix.Exlam.{Utils }
  def run(args \\["-cf"]) do
    case args do
      ["-cf"] -> deploy_with_cloudformation(args)
      ["-cli"] -> deploy_with_cli(args)
      x -> "Invalid option(s) #{inspect x}.  Please use -cf for cloudformation, or -cli for using the AWS CLI"
    end
  end
  def deploy_with_cloudformation(args) do
    Mix.Task.run("loadpaths", [])
    config = Mix.Tasks.Exlam.Package.makeConfig
    Utils.qcmd "aws s3 cp lambda_deploy.zip #{config.sam_s3_bucket}"
    Utils.qcmd "aws cloudformation deploy --template-file deploy/deploy.yaml --stack-name #{config.sam_stack_name} --profile exlam-deployer1"
  end
  def deploy_with_cli(args) do
    Mix.Task.run("loadpaths", [])
    config = Mix.Tasks.Exlam.Package.makeConfig
    Utils.qcmd "aws lambda create-function --region us-west-2 --function-name #{config.app} --zip-file fileb://./lambda_deploy.zip --handler index.handler --runtime nodejs4.3 --profile exlam-deployer1 --timeout #{config.sam_timeout} --memory-size #{config.sam_mem_size} --role #{config.sam_role_arn}"
  end
end

defmodule Mix.Tasks.Exlam.Package do
  use Mix.Config
  @deploy_stage_dir "deploy"
  def run(args) do
    Mix.Task.run("loadpaths", [])
    config = makeConfig
    #checkEnv(config)
    clean(config)
    checkNodeSyntax()
    genRelease(config)
    prep(config)
  end
  def prep(config) do
    Mix.shell.info "Prepping deployment"
    Mix.shell.info "Starting and stopping app"
    {out,code} = System.cmd("/bin/sh",["-c", "./#{@deploy_stage_dir}/burn/bin/#{config.app} start"])
    :timer.sleep(1000)
    {out2,code2} = System.cmd("/bin/sh",["-c", "./#{@deploy_stage_dir}/burn/bin/#{config.app} stop"])
    if (code != 0 || code2 != 0) do
      raise "error starting release #{out} #{out2}"
    end
    Mix.shell.info "updating permissions"
    
    #  install is "slicer", invoke and init is random user
    # homes and var need to be writable, need to thin down var
    File.write!("./deploy/burn/dumblog.log","")
    File.chmod!("./deploy/burn/dumblog.log",0o777)
    File.chmod!("./deploy/homes",0o777) 
    System.cmd("chmod",["-R","777","./deploy/burn/var"])
    File.rename("./lambda_deploy.zip","lambda_deploy.#{config.version}.old")
    Mix.shell.info "zipping files"
    {out,zip_code} = case config.zip do
      :fast -> System.cmd("/bin/sh",["-c","cd deploy;zip -r ../lambda_deploy.zip . --compression-method store"])
      _ ->
        {out,zip_code} = System.cmd("/bin/sh",["-c","cd deploy;zip -r ../lambda_deploy.zip ."])
    end
  end
  def makeConfig do
    conf = @deploy_stage_dir <> "/config.exs"
    Mix.shell.info "reading config #{conf}"
    lst = Mix.Config.read! conf
    erts_version = :erlang.system_info(:version)
    exlam_config = Enum.into lst[:exlam],%{}
    Mix.shell.info inspect exlam_config, pretty: true
    config = Mix.Project.config |> Enum.into %{} 
    Map.merge(config,exlam_config)
  end
  def genRelease(config) do
    oldenv = Mix.env
    if (config.use_phoenix) do
      Mix.Task.run("phoenix.digest");
    else
      # ensure there is some web server
      try do
        HttpServer.__info__(:functions)
      rescue
        e -> raise "No HttpServer available\n\n"  <> inspect e
      end
    end
    :ok = Mix.Task.run("release",["--env=prod"])
    app = config[:app]
    version = config[:version]
    File.mkdir_p!("deploy/homes");
    File.mkdir_p!(config.tmp_dir);
    {out,exit_code} = System.cmd("tar",["--directory=./deploy/burn","-zxvf","./rel/#{app}/releases/#{version}/#{app}.tar.gz"])
    case exit_code do
      0 -> true
      _ -> raise "error extracting archive: #{exit_code} \n\t#{out}"
    end
    Mix.env oldenv
  end
  def checkNodeSyntax(file \\"deploy/index.js") do
    case File.exists?(file) do
      true -> doNodeC(file)
      _ -> raise "#{file} not found"
    end
  end
  def doNodeC(file) do
    {out,code} = System.cmd("node",["-c",file])
    if code != 0 do
      raise "error with node syntax: " <> out
    end
  end
  def checkEnv(config) do
    Mix.Task.load_all()
    checkBin("node", "Please install a version of node compatable with AWS Lambda");
    checkBin("aws","Please install the AWS CLI")
    checkTask(Mix.Tasks.Release,"Please add and install distillery")
    if (Map.has_key?(config,:use_phoenix)) do
      checkTask(Mix.Tasks.Phoenix,"Please add and install phoenix")
    end
    true
  end
  def checkTask(module,msg \\"") do
    case Mix.Task.task? module do
      true -> true
      _ -> 
        Mix.shell.info "Available Tasks: \n\n#{inspect Mix.Task.all_modules(),pretty: true}"
        raise "Task #{module} not found.  " <> msg
    end
  end
  def checkBin(bin,msg \\"") do
    case System.find_executable(bin) do
      s when is_binary(s)-> true
      _ -> raise "can't find executable: #{bin}" <> msg
    end
  end
  def clean(config) do
    Mix.shell.info "removing previous directory " <> config.tmp_dir
    File.rm_rf(config.tmp_dir)
  end
end

defmodule Mix.Exlam.Utils do
  @moduledoc false
  def qcmd(cmd) do
    Mix.shell.info "Running command: \n\t#{inspect cmd}"
    System.cmd("sh",["-c",cmd])
  end
  def template(name, params \\ []) do
    IO.puts "params: \n\t" <> inspect params
    config = Mix.Project.config
    try do
      template_path = ""
      if (config[:app] == :exlam) do
        template_path = Path.join(["./priv", "templates", "#{name}.eex"])
      else
        template_path = Path.join(["#{:code.priv_dir(:exlam)}", "templates", "#{name}.eex"])
      end
      {:ok, EEx.eval_file(template_path, params)}
    rescue
      e ->
        IO.puts "crap"
        {:error, e.__struct__.message(e)}
    end
  end 
end

