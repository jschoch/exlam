defmodule ExlamTest do
  use ExUnit.Case
  doctest Exlam

  setup_all do
    IO.puts "setup"
    #Mix.Task.run("new",["test_app"])
    Mix.Task.run("exlam.init");
  end
  test "check bins and tasks works" do
    t = Mix.Tasks.Exlam.Package.checkBin("node") 
    assert t != nil
    assert_raise RuntimeError, 
      fn -> Mix.Tasks.Exlam.Package.checkBin("nodenothere") end

    r = Mix.Tasks.Exlam.Package.checkTask(Mix.Tasks.Release)
    assert r
    assert_raise RuntimeError,
      fn -> Mix.Tasks.Exlam.Package.checkTask(NotExisting) end
  end
  test "check env" do
    assert Mix.Tasks.Exlam.Package.checkEnv(%{})
  end
  test "test clean" do
    {:ok,x} = Mix.Tasks.Exlam.Package.clean %{tmp_dir: "./deploy/burn"}
    IO.puts "X: " <> inspect x
  end
  test "test index" do
    f = File.rm("deploy/index.js")
    r = fn file -> Mix.Tasks.Exlam.Package.checkNodeSyntax(file) end
    assert_raise RuntimeError, fn -> r.("./deploy/index.js") end
    config =  Mix.Tasks.Exlam.Package.makeConfig
    Mix.Tasks.Exlam.Init.genIndex config
    res = Mix.Tasks.Exlam.Package.checkNodeSyntax()
    File.write!("./deploy/bad.js","# fo !!#@@#23();")
    assert_raise( RuntimeError, fn -> r.("./deploy/bad.js") end)
  end

  #@tag :full
  test "release" do
    config = Mix.Tasks.Exlam.Package.makeConfig
    IO.puts inspect config
    r = Mix.Tasks.Exlam.Package.genRelease(config)
  end
  test "make Config" do
    config = Mix.Tasks.Exlam.Init.genConfig()
    made_config = Mix.Tasks.Exlam.Package.makeConfig
    IO.inspect made_config 
  end
  test "gen sam template" do
    config = Mix.Tasks.Exlam.Init.genConfig()
    config = Mix.Tasks.Exlam.Package.makeConfig
    sam = Mix.Tasks.Exlam.Init.genSam(config)
    assert sam != nil
  end
  test "prep works" do
    config = Mix.Tasks.Exlam.Init.genConfig()
    config = Mix.Tasks.Exlam.Package.makeConfig
    Mix.Tasks.Exlam.Package.genRelease(config)
    Mix.Tasks.Exlam.Package.prep(config)
  end
  test "zip config" do
    assert false, "not done yet"
  end
  test "http port" do
    assert false, "not done yet"
  end
  test "aws cli version check" do
    assert false, "not done yet"
  end
  test "security lock down" do
    assert false, "not done yet"
  end

end
