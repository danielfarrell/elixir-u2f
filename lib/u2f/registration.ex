defmodule U2F.Registration do
  defstruct [:key_handle, :public_key, :certificate, :counter]
end
