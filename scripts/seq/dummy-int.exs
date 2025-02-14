#check preconditions
#check if ip command is available
#if it does not work return with error


#Setup enviroment
#create a new dummy interface with ip 172.20.99.99/24

#execute
#ping 172.20.99.99

#check postconditions
#check if the dummy interface is still up
#check if the ip is still assigned to the dummy interface
#check if the ping is successful

#Teardown enviroment
# destroy the dummy interface

#return result
# the structure is the following:
# %{
#   "status" => "success" | "error"
#   "result" => %{
#     "want" => "Create a dummy interface with ip 172.20.99.99/24"
#     "got" => "Create a dummy interface with ip 172.20.99.99/24"
#   }
# }

defmodule DummyInterface do
  def check_root do
    case System.cmd("id", ["-u"], stderr_to_stdout: true) do
      {"0\n", 0} -> :ok
      _ -> {:error, "Root privileges required"}
    end
  end

  def check_ip_command do
    case System.cmd("which", ["ip"], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {_, _} -> {:error, "ip command not found"}
    end
  end

  def setup_environment do
    System.cmd("ip", ["link", "add", "dummy0", "type", "dummy"])
    System.cmd("ip", ["addr", "add", "172.20.99.99/24", "dev", "dummy0"])
    System.cmd("ip", ["link", "set", "dummy0", "up"])
  end

  def execute_test do
    {output, status} = System.cmd("ping", ["-c", "1", "172.20.99.99"])
    {output, status}
  end

  def check_postconditions do
    # Check if interface exists
    {interface_output, _} = System.cmd("ip", ["link", "show", "dummy0"])
    interface_up = String.contains?(interface_output, "dummy0")

    # Check if IP is assigned
    {ip_output, _} = System.cmd("ip", ["addr", "show", "dummy0"])
    ip_assigned = String.contains?(ip_output, "172.20.99.99")

    {ping_output, ping_status} = execute_test()
    ping_success = ping_status == 0

    {interface_up, ip_assigned, ping_success}
  end

  def teardown_environment do
    System.cmd("ip", ["link", "delete", "dummy0"])
  end

  def run_test do
    with :ok <- check_root(),
         :ok <- check_ip_command() do
      try do
        setup_environment()
        {_, ping_status} = execute_test()
        {interface_up, ip_assigned, ping_success} = check_postconditions()
        teardown_environment()

        if interface_up and ip_assigned and ping_success do
          %{
            "status" => "success",
            "result" => %{
              "want" => "Create a dummy interface with ip 172.20.99.99/24",
              "got" => "Create a dummy interface with ip 172.20.99.99/24"
            }
          }
        else
          if !ip_assigned do
          %{
            "status" => "failed",
            "result" => %{
              "want" => "Create a dummy interface with ip 172.20.99.99/24",
              "got" => "Failed to create or verify dummy interface"
            }
          }
          else
          %{
            "status" => "error",
            "result" => %{
              "want" => "Create a dummy interface with ip 172.20.99.99/24",
              "got" => "Failed to create or verify dummy interface"
            }
          }
          end
        end
      rescue
        e ->
          %{
            "status" => "error",
            "result" => %{
              "want" => "Create a dummy interface with ip 172.20.99.99/24",
              "got" => "Error: #{Exception.message(e)}"
            }
          }
      end
    else
      {:error, msg} ->
        %{
          "status" => "error",
          "result" => %{
            "want" => "Create a dummy interface with ip 172.20.99.99/24",
            "got" => "Error: #{msg}"
          }
        }
    end
  end
end

# Run the test and return the result directly
result = DummyInterface.run_test()
Jason.encode!(result)
#result  # This should be the last expression
