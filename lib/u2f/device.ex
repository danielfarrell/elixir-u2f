defmodule U2F.Device do
  use GenServer
  defstruct [:app_id, :counter, :key_handle_raw, :cert_subject]
  @curve "prime256v1"

  def start_link(default // []) do
    GenServer.start_link(__MODULE__, default)
  end

  def increment(pid, app_id) do
    GenServer.cast(pid, {:increment, app_id, 1})
  end

  def count(pid, app_id) do
    GenServer.call(pid, {:count, app_id})
  end

  def add_app(pid, app_id) do
    GenServer.cast(pid, {:add, {app_id: app_id, counter: 0}})
  end

  def handle_call({:count, app_id}, _from, state) do
    {:reply, counter}
  end

  def handle_cast({:increment, app_id, num}, state) do
    {:noreply, counter + num}
  end

  # A registerResponse hash as returned by the u2f.register JavaScript API.
  #
  # challenge - The challenge to sign.
  # error     - Boolean. Whether to return an error response (optional).
  #
  # Returns a JSON encoded Hash String.
  def register_response({:ok, challenge}) do
    client_data_json = client_data(U2F::ClientData.registration_type, challenge)
    %{registrationData: reg_registration_data(client_data_json), clientData: U2F.Base64.encode(client_data_json)}
      |> Poison.encode!
  end

  def register_response({:error, challenge}) do
    %{errorCode: 4} |> Poison.encode!
  end

  # A SignResponse hash as returned by the u2f.sign JavaScript API.
  #
  # challenge - The challenge to sign.
  #
  # Returns a JSON encoded Hash String.
  def sign_response(challenge) do
    client_data_json = client_data(U2F::ClientData.authentication_type, challenge)
    %{clientData: U2F.Base64.encode(client_data_json), keyHandle: U2F.Base64.encode(key_handle_raw),
      signatureData: auth_signature_data(client_data_json)} |> Poison.encode!
  end

  # The appId specific public key as returned in the registrationData field of
  # a RegisterResponse Hash.
  #
  # Returns a binary formatted EC public key String.
  def origin_public_key_raw do
    [origin_key.public_key.to_bn.to_s(16)].pack('H*')
  end

  # The raw device attestation certificate as returned in the registrationData
  # field of a RegisterResponse Hash.
  #
  # Returns a DER formatted certificate String.
  def cert_raw do
    cert.to_der
  end

  # The registrationData field returns in a RegisterResponse Hash.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns a url-safe base64 encoded binary String.
  defp reg_registration_data(client_data_json) do
    [
      5,
      origin_public_key_raw,
      key_handle_raw.bytesize,
      key_handle_raw,
      cert_raw,
      reg_signature(client_data_json)
    ].pack("CA65CA#{key_handle_raw.bytesize}A#{cert_raw.bytesize}A*")
      |> U2F.Base64.encode
  end

  # The signature field of a registrationData field of a RegisterResponse.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns an ECDSA signature String.
  defp reg_signature(client_data_json) do
    payload = [
      "\x00",
      U2F.Crypto.digest(app_id),
      U2F.Crypto.digest(client_data_json),
      key_handle_raw,
      origin_public_key_raw
    ] |> Enum.join
    U2F.Crypto.sign(payload, cert_key)
  end

  # The signatureData field of a SignResponse Hash.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns a url-safe base64 encoded binary String.
  defp auth_signature_data(client_data_json) do
    [
      1, # User present
      self.counter += 1,
      auth_signature(client_data_json)
    ].pack("CNA*")
      |> U2F.Base64.encode
  end

  # The signature field of a signatureData field of a SignResponse Hash.
  #
  # client_data_json - The JSON encoded clientData String.
  #
  # Returns an ECDSA signature String.
  defp auth_signature(client_data_json) do
    data = [
      U2F.Crypto.digest(app_id)
      1, # User present
      counter,
      U2F.Crypto.digest(client_data_json)
    ].pack("A32CNA32")

    U2F.Crypto.sign(data, origin_key)
  end

  # The clientData hash as returned by registration and authentication
  # responses.
  #
  # typ       - The String value for the 'typ' field.
  # challenge - The String url-safe base64 encoded challenge parameter.
  #
  # Returns a JSON encoded Hash String.
  defp client_data(typ, challenge) do
    %{
      challenge: challenge,
      origin: app_id,
      typ: typ
    } |> Poison.encode!
  end

  # The appId-specific public/private key.
  #
  # Returns a OpenSSL::PKey::EC instance.
  defp origin_key do
    @origin_key ||= generate_ec_key
  end

  # The self-signed device attestation certificate.
  #
  # Returns a OpenSSL::X509::Certificate instance.
  defp cert do
    @cert ||= OpenSSL::X509::Certificate.new.tap do |c|
      c.subject = c.issuer = OpenSSL::X509::Name.parse(cert_subject)
      c.not_before = Time.now
      c.not_after = Time.now + 365 * 24 * 60 * 60
      c.public_key = cert_key
      c.serial = 0x1
      c.version = 0x0
      U2F.Crypto.sign(c, cert_key)
    end
  end

  # The public key used for signing the device certificate.
  #
  # Returns a OpenSSL::PKey::EC instance.
  defp cert_key do
    @cert_key ||= generate_ec_key
  end

  # Generate an eliptic curve public/private key.
  #
  # Returns a OpenSSL::PKey::EC instance.
  defp generate_ec_key do
    OpenSSL::PKey::EC.new().tap do |ec|
      ec.group = OpenSSL::PKey::EC::Group.new(@curve)
      ec.generate_key
      # https://bugs.ruby-lang.org/issues/8177
      ec.define_singleton_method(:private?) { private_key? }
      ec.define_singleton_method(:public?) { public_key? }
    end
  end

end
