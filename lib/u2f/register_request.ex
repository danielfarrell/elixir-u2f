defmodule U2F.RegisterRequest do
  defstruct [:challenge, :app_id, :version]
end
