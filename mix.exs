defmodule StarkCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :starkcore,
      name: :starkcore,
      version: "0.1.1",
      homepage_url: "https://starkinfra.com",
      source_url: "https://github.com/starkinfra/core-elixir",
      description: description(),
      elixir: "~> 1.17.2",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  defp package do
    [
      maintainers: ["Stark Bank"],
      licenses: [:MIT],
      links: %{
        "StarkInfra" => "https://starkinfra.com",
        "GitHub" => "https://github.com/starkinfra/core-elixir"
      }
    ]
  end

  defp description do
    "Core functionalities for the StarkInfra and StarkBank Elixir SDKs"
  end

  def application do
    [
      extra_applications: [
        :inets,
        :public_key,
        :ssl
      ]
    ]
  end

  defp deps do
    [
      {:starkbank_ecdsa, "~> 1.1.0"},
      {:jason, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
