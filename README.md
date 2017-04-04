# Exlam

This is code is not production ready, many kinks to be worked out.  Contributors welcome.

## Deploy apps to AWS Lambda

ensure you have distillery installed and a web server 
  insecure testing example: 

```elixir
  defp deps do
    [
      {:distillery, "~> 0.10"},
      {:http_server, git: "https://github.com/jschoch/elixir_http_server"}
    ]
```

Ensure the web server starts 

```elixir
  def application do
    [applications: [:logger,:http_server]]
  end
```

Ensure latest awscli via sudo pip install --upgrade awscli

Get distillery configured via
`mix release.init`

Initilize Exlam
`mix exlam.init`

Edit deploy/config.exs and deploy/deploy.yaml with correct values and then package your app
`mix exlam.package`

Run the deployer for your first deploy, this creates AWS resources you will be billed for.

`mix exlam.deploy -cli`

To update your functionrun:

`mix exlam.package;mix exlam.uf`

configure role and deployer policy

working policy, 

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1480632540000",
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateChangeSet"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}

Backlog:


configure with codebuild
enable non-current env ERTS libs via distillery
support umbrella apps
configurable web server
flag and optionally remove erl_crash.dump files to reduce size of deploy.zip


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `exlam` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:exlam, "~> 0.1.0"}]
    end
    ```

