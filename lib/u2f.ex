defmodule U2F do
  @versions ["U2F_V2"]

  def versions do
    @versions
  end

  def challenge do
    U2F.Crypto.random(32) |> U2F.Base64.encode
  end

  def registration_requests(app_id) do
    [%U2F.RegisterRequest{challenge: challenge, app_id: app_id}]
  end

  def authentication_requests(app_id, key_handles) do
    # key_handles |> Enum.map(&build_sign_request(app_id))
  end

  def build_sign_request(key_handle, app_id) do
    %U2F.SignRequest{key_handle: key_handle, challenge: challenge, app_id: app_id}
  end

  def public_key_pem(key) do
    # fail PublicKeyDecodeError unless key.length == 65 && key[0] == "\x04"
    # # http://tools.ietf.org/html/rfc5480
    # der = OpenSSL::ASN1::Sequence([
    #   OpenSSL::ASN1::Sequence([
    #     OpenSSL::ASN1::ObjectId('1.2.840.10045.2.1'),  # id-ecPublicKey
    #     OpenSSL::ASN1::ObjectId('1.2.840.10045.3.1.7') # secp256r1
    #   ]),
    #   OpenSSL::ASN1::BitString(key)
    # ]).to_der
    #
    # pem = "-----BEGIN PUBLIC KEY-----\r\n" <>
    #       Base64.strict_encode64(der).scan(/.{1,64}/).join("\r\n") <>
    #       "\r\n-----END PUBLIC KEY-----"
    # pem
  end

  def register!(challenges, response) do
    # challenge = challenges.detect do |chg|
    #   chg == response.client_data.challenge
    # end
    #
    # fail UnmatchedChallengeError unless challenge
    #
    # fail ClientDataTypeError unless response.client_data.registration?
    #
    # # Validate public key
    # U2F.public_key_pem(response.public_key_raw)
    #
    # # TODO:
    # # unless U2F.validate_certificate(response.certificate_raw)
    # #   fail AttestationVerificationError
    # # end
    #
    # fail AttestationSignatureError unless response.verify(app_id)
    #
    # registration = Registration.new(
    #   response.key_handle,
    #   response.public_key,
    #   response.certificate
    # )
    # registration
  end


  def authenticate!(challenges, response, registration_public_key, registration_counter) do
    # # TODO: check that it's the correct key_handle as well
    # unless challenges.include?(response.client_data.challenge)
    #   fail NoMatchingRequestError
    # end
    #
    # fail ClientDataTypeError unless response.client_data.authentication?
    #
    # pem = U2F.public_key_pem(registration_public_key)
    #
    # fail AuthenticationFailedError unless response.verify(app_id, pem)
    #
    # fail UserNotPresentError unless response.user_present?
    #
    # unless response.counter > registration_counter
    #   fail CounterTooLowError
    # end
  end

end
