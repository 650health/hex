defmodule Hex do
  @moduledoc false

  def start() do
    IO.puts("Hex.start()")
    # IO.inspect(:code.which(:wpool))
    Code.ensure_compiled!(:katipo)
    Code.ensure_compiled!(:worker_pool)
    IO.inspect(:code.which(:katipo))
    Code.ensure_loaded!(:wpool)
    Code.ensure_loaded!(:katipo)
    Code.ensure_loaded!(:katipo_pool)

    {:ok, _} = Application.ensure_all_started(:hex)
  end

  def stop() do
    case Application.stop(:hex) do
      :ok -> :ok
      {:error, {:not_started, :hex}} -> :ok
    end
  end

  # For compatibility during development
  def start(start_type, start_args) do
    Hex.Application.start(start_type, start_args)
  end

  def version(), do: unquote(Mix.Project.config()[:version])
  def elixir_version(), do: unquote(System.version())
  def otp_version(), do: unquote(Hex.Utils.otp_version())
end
