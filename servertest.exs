#!/usr/bin/env -S ERL_FLAGS=+B elixir
Mix.install([{:ex_doc, "~> 0.24", only: :dev, runtime: false}, {:earmark, "~> 1.4"}, {:jason, "~> 1.0"}])

## Check if running as root
#if System.cmd("id", ["-u"]) |> elem(0) |> String.trim() != "0" do
#  IO.puts("Error: This script must be run with root privileges (sudo).")
#  System.halt(1)
#end

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

    sequential_results =
      if Enum.empty?(scripts_seq) do
        IO.puts("No scripts found in the directory: #{input_path}/seq")
        %{}
      else
        results = execute_scripts_sequential(input_path <> "/seq", scripts_seq)
        IO.puts("Sequential results: #{inspect(results)}")
        results
      end

    parallel_results =
      if Enum.empty?(scripts_parallel) do
        IO.puts("No scripts found in the directory: #{input_path}/parallel")
        %{}
      else
        results = execute_scripts_parallel(input_path <> "/parallel", scripts_parallel)
        IO.puts("Parallel results: #{inspect(results)}")
        results
      end

    # Transform results into the desired format
    initial_results = %{"success" => [],"failed" => [],"error" => [], "unknown" => []}
    results_with_sequential = add_results_to_list(initial_results, sequential_results, "sequential")
    final_results = add_results_to_list(results_with_sequential, parallel_results, "parallel")

    formatted_results = %{
      "results" => final_results
    }

    json_output = Jason.encode!(formatted_results, pretty: true)
    IO.puts(json_output)

    # Write the JSON to output.json
    File.write!("output.json", json_output)

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

  def add_results_to_list(results, script_results, execution_type) do
    script_results
    |> Enum.reduce(results, fn {key, value}, acc ->
      # Attempt to decode the JSON string value. If it fails, use the raw value
      try do
        IO.puts("value: #{inspect(value)}")
        IO.puts("End value")
        case Jason.decode!(value) do
          %{"result" => result, "status" => status} ->
            entry = %{
              "id" => key,
              "result" => result,
              "type" => execution_type
            }

            IO.puts("name: #{inspect(key)}")
            IO.puts("status: #{inspect(status)}")
            case status do
              "success" -> Map.update!(acc, "success", &(&1 ++ [entry]))
              "error" -> Map.update!(acc, "error", &(&1 ++ [entry]))
              "failed" -> Map.update!(acc, "failed", &(&1 ++ [entry]))
              _ -> Map.update!(acc, "unknown", &(&1 ++ [entry]))
            end
          other_value ->
            IO.puts("other_value: #{inspect(other_value)}")
            entry = %{
              "id" => key,
              "result" => other_value,
              "type" => execution_type
            }
            Map.update!(acc, "unknown", &(&1 ++ [entry]))
        end
      rescue
        _ ->
          entry = %{
            "id" => key,
            "result" => value,
            "type" => execution_type
          }
          Map.update!(acc, "unknown", &(&1 ++ [entry]))
      end
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
