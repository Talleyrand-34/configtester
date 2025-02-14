#!/usr/bin/env -S ERL_FLAGS=+B elixir
Mix.install([{:ex_doc, "~> 0.24", only: :dev, runtime: false}, {:earmark, "~> 1.4"}, {:jason, "~> 1.0"}])

if System.get_env("DEPS_ONLY") == "true" do
  System.halt(0)
  Process.sleep(:infinity)
end

defmodule BrowseDir do
  @moduledoc """
  Module to deploy Markdown files.
  """

  @doc """
  Process Markdown files in a given directory and write HTML files.
  """
  def execute_scripts(input_path) do
    scripts_seq =
      File.ls!(input_path <> "/seq")
      |> Enum.filter(&(Path.extname(&1) == ".exs"))
    scripts_parallel =
      File.ls!(input_path <> "/parallel")
      |> Enum.filter(&(Path.extname(&1) == ".exs"))

    sequential_results = nil
    parallel_results = nil

    if Enum.empty?(scripts_seq) do
      IO.puts("No scripts found in the directory: #{input_path}/seq")
    else
      sequential_results = execute_scripts_sequential(input_path <> "/seq", scripts_seq)
      IO.puts("Sequential results: #{inspect(sequential_results)}")
    end

    if Enum.empty?(scripts_parallel) do
      IO.puts("No scripts found in the directory: #{input_path}/parallel")
    else
      parallel_results = execute_scripts_parallel(input_path <> "/parallel", scripts_parallel)
      IO.puts("Parallel results: #{inspect(parallel_results)}")
    end

    # Transform results into the desired format
    results = []
    results = add_results_to_list(results, sequential_results || %{}, "sequential")
    results = add_results_to_list(results, parallel_results || %{}, "parallel")

    formatted_results = %{
      "results" => results
    }

    IO.puts(Jason.encode!(formatted_results, pretty: true))
    formatted_results
  end

  def execute_scripts_sequential(input_path, scripts) do
    scripts
    |> Enum.reduce(%{}, fn script, acc ->
      script_path = Path.join(input_path, script)
      {result, _} = Code.eval_file(script_path)
      Map.put(acc, Path.basename(script, ".exs"), result)
    end)
  end

  def execute_scripts_parallel(input_path, scripts) do
    scripts
    |> Task.async_stream(fn script ->
      script_path = Path.join(input_path, script)
      {result, _} = Code.eval_file(script_path)
      {script, result}
    end)
    |> Enum.reduce(%{}, fn {:ok, {script, result}}, acc ->
      Map.put(acc, Path.basename(script, ".exs"), result)
    end)
  end

  # Helper function to format results
  defp add_results_to_list(list, results, execution_type) do
    results
    |> Enum.reduce(list, fn {name, result}, acc ->
      decoded_log =
        try do
          Jason.decode!(result)
        rescue
          _ -> result
        end

      formatted_result = %{
        "name" => "#{name}.exs",
        "execution" => execution_type,
        "result" => "success",
        "log" => decoded_log
      }
      [formatted_result | acc]
    end)
  end
end



# --------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------
defmodule Main do
  @args [
    help: :boolean,
    input: :string,
    output: :string
  ]

  def main(args) do
    {parsed, args} = OptionParser.parse!(args, strict: @args)
    IO.inspect(parsed)
    IO.inspect(args)
    cmd(parsed, args)
  end

  defp cmd([help: true], _), do: IO.puts(@moduledoc)

  defp cmd(parsed, _args) do
    input_path = parsed[:input] || "./scripts"
    output_path = parsed[:output] || "./test/html/"
    IO.puts("----")
    IO.inspect(input_path)
    IO.inspect(output_path)

    BrowseDir.execute_scripts(input_path)
  end
end

Main.main(System.argv())
