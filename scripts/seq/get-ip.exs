defmodule IpFetcher do
  @moduledoc """
  A module to fetch the IP address of a given interface and return it in JSON format.
  """

  def fetch_ip(interface) do
    # Execute the shell command to get the IP address
    command = "ip addr show #{interface} | grep 'inet ' | awk '{print $2}' | cut -d/ -f1"
    {output, 0} = System.cmd("bash", ["-c", command])

    # Clean up the output and create response structure
    ip_address = String.trim(output)
    response = %{
      status: "success",
      result: ip_address
    }

    # Convert the map to JSON
    Jason.encode!(response)
  end
end

# Usage
interface = "wlo1"
IpFetcher.fetch_ip(interface)
