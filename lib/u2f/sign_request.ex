defmodule U2F.SignRequest do
  defstruct [:key_handle, :challenge, :app_id, :version]
end
