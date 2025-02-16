# Mix.install([{:gen_icmp, github: "msantos/gen_icmp"}, {:jason, "~> 1.2"}])
# Mix.install([  {:jason, "~> 1.2"},{:gen_icmp, github: "msantos/gen_icmp"}])
# defmodule Ping do
#   @spec do_ping(:inet | :inet6, String.t(), pos_integer()) :: {:ok, String.t()} | {:error, term}
#   def do_ping(type, host, timeout) do
#     try do
#       case :gen_icmp.ping(String.to_charlist(host), [type, {:timeout, timeout}]) do
#         [{:ok, _host, _address, reply_addr, _details, _payload}] ->
#           {:ok, :inet_parse.ntoa(reply_addr) |> to_string}
#
#         [{:error, icmp_reason, _host, _address, _reply_addr, _details, _payload}] ->
#           {:error, icmp_reason}
#
#         [{:error, reason, _host, _address}] ->
#           {:error, reason}
#
#         [{:error, reason}] ->
#           {:error, reason}
#       end
#     rescue
#       e ->
#         IO.inspect(e, label: "Error in do_ping")
#         {:error, :unknown}
#     end
#   end
#
#   def ping(node, type, host, timeout) when is_atom(node) and is_atom(type) and is_binary(host) and is_integer(timeout) do
#     parent_pid = self()
#
#     Node.spawn(node, fn ->
#       result =
#         case do_ping(type, host, timeout) do
#           {:ok, ip_address} ->
#             {:ok, ip_address}
#           {:error, reason} ->
#             {:error, to_string(reason)} # Ensure reason is a string
#         end
#
#       json_result =
#         case result do
#           {:ok, ip_address} ->
#             Jason.encode!(%{status: "ok", ip_address: ip_address})
#           {:error, reason} ->
#             Jason.encode!(%{status: "error", reason: reason})
#         end
#
#       send(parent_pid, {:ping_result, json_result})
#     end)
#
#     receive do
#       {:ping_result, json_result} ->
#         json_result
#     after
#        timeout + 1000 -> #Increased the timeout to prevent early timeout
#         Jason.encode!(%{status: "error", reason: "Timeout"})
#     end
#   end
#   @spec bidirectional_ping(atom(), atom()) :: {String.t(), String.t()}
#     def bidirectional_ping(node1, node2) do
#       # Extract IP address from the node atoms using IPUtils module.
#       case IPUtils.extract_ip_from_atom(node1) do
#         {:ok, ip1} -> 
#           case IPUtils.extract_ip_from_atom(node2) do
#             {:ok, ip2} -> 
#               # Ping from node1 to node2 and then from node2 back to node1.
#               ping(node1, :inet, ip2, 5000)
#               |> IO.inspect(label: "Ping Result from #{ip1} to #{ip2}")
#
#               ping(node2, :inet, ip1, 5000)
#               |> IO.inspect(label: "Ping Result from #{ip2} to #{ip1}")
#
#             error -> error # Handle extraction error for node2
#           end
#
#         error -> error # Handle extraction error for node1
#       end
#     end
# end

# defmodule IPUtils do
#   @spec extract_ip_from_atom(atom) :: {:ok, String.t()} | {:error, :invalid_format}
#   def extract_ip_from_atom(atom) when is_atom(atom) do
#     atom_string = Atom.to_string(atom)
#     case String.split(atom_string, "@") do
#       [_, ip_address] ->
#         {:ok,  ip_address}
#       _ ->
#         {:error, :invalid_format}
#     end
#   end
# end


# :erlang.set_cookie(node(), :secret)
#
# cookie = :erlang.get_cookie()
# IO.puts "Cookie on this node: #{cookie}"
# Node.connect(:"test@10.0.0.99")
# Node.connect(:"test2@10.0.0.122")
# list= Node.list()
# IO.inspect(list)
# Node.ping(:"test2@10.0.0.122") # Check connection
# result=Ping.ping(:"test2@10.0.0.122", :inet, "10.0.0.122", 5000)
# IO.puts("ping result")
# IO.inspect(result)
# IO.puts("bidirectional_ping result")
# Ping.bidirectional_ping(:"test@10.0.0.99",:"test2@10.0.0.122")
defmodule Biping do
  @spec bidirectional_ping(atom(), atom()) :: {String.t(), String.t()}
    def bidirectional_ping(node1, node2) do
      # Extract IP address from the node atoms using IPUtils module.
      case IPUtils.extract_ip_from_atom(node1) do
        {:ok, ip1} -> 
          case IPUtils.extract_ip_from_atom(node2) do
            {:ok, ip2} -> 
              # Ping from node1 to node2 and then from node2 back to node1.
              Ping.ping(node1, :inet, ip2, 5000)
              |> IO.inspect(label: "Ping Result from #{ip1} to #{ip2}")

              Ping.ping(node2, :inet, ip1, 5000)
              |> IO.inspect(label: "Ping Result from #{ip2} to #{ip1}")

            error -> error # Handle extraction error for node2
          end

        error -> error # Handle extraction error for node1
      end
    end

end
defmodule ConfigLoader do
  @spec load_config(String.t()) :: {:ok, map()} | {:error, term}
  def load_config(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        Jason.decode(content)
      {:error, reason} ->
        {:error, reason}
    end
  end
end

defmodule LocalMain do
  def run do
    case ConfigLoader.load_config("./biping_config.json") do
      {:ok, %{"cookie" => cookie, "nodes" => nodes}} ->
        :erlang.set_cookie(node(), String.to_atom(cookie))

        # Display the cookie on this node
        current_cookie = :erlang.get_cookie()
        IO.puts("Cookie on this node: #{current_cookie}")

        # Connect to other nodes
        Enum.each(nodes, fn node_name ->
          Node.connect(String.to_atom(node_name))
          IO.puts("Connected to #{node_name}")
        end)

        # List connected nodes
        list = Node.list()
        IO.inspect(list)

        # Ping test2 node
        result = Ping.ping(:"test2@10.0.0.122", :inet, "10.0.0.122", 5000)
        IO.puts("Ping result:")
        IO.inspect(result)

        # Bidirectional ping
        IO.puts("Bidirectional ping result:")
        Biping.bidirectional_ping(:"test@10.0.0.99", :"test2@10.0.0.122")

      {:error, reason} ->
        IO.puts("Failed to load config: #{reason}")
    end
  end
end

# Run the main function when the script is executed.
LocalMain.run()

