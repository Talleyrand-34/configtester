#check preconditions
#check if ip command is available
#if it does not work return with error


# -------------------------------------------------------
#Setup enviroment
#create a new dummy interface with ip 172.20.99.99/24

# -------------------------------------------------------
#execute
#ping 172.20.99.99

# -------------------------------------------------------
#check postconditions
#check if the dummy interface is still up
#check if the ip is still assigned to the dummy interface
#check if the ping is successful

# -------------------------------------------------------
#Teardown enviroment
# destroy the dummy interface
# -------------------------------------------------------
#return result
# the structure is the following:
# %{
#   "status" => "success" | "error"
#   "result" => %{
#     "want" => "Create a dummy interface with ip 172.20.99.99/24"
#     "got" => "Create a dummy interface with ip 172.20.99.99/24"
#   }
# }

# IMPORTANT:
#return Jason.encode!(result)
