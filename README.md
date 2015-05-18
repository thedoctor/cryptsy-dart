# Cryptsy

A Dart library for the [Cryptsy API (v2)](https://www.cryptsy.com/pages/apiv2).

Lets you connect to your Cryptsy account and do Super Dope Altcoin Trading Stuff.


## Usage

This library adheres pretty closely to their [python reference client](https://github.com/ScriptProdigy/CryptsyPythonV2).

The biggest difference (besides top-level client functions being idiomatically camelcase) is in the initializer. Because of a [bug](https://github.com/izaera/cipher/issues/93) in (currently) the only dart library that supports HMAC-SHA512 (which Cryptsy uses for authentication), you need to provide a Sha512Hmac-er function in the constructor. The example below shows grabbign an hmac function from a js context.

You also will provide an HTTP client factory. (Does anyone know a better way to make an environment-agnostic library that uses HTTP calls?)

    import 'package:cryptsy/cryptsy.dart';

    main() {
      // For in-browser use
      _clientFactory() => new BrowserClient();

      var cc = new Cryptsy(
        publicKey: 'cryptsy API pubkey',
        privateKey: 'cryptsy API privkey',
        hmac: context['CryptoJS']['HmacSHA512'],
        clientFactory: _clientFactory);

      cc.markets().then((response) => querySelector('#something').text = response.body);
    }

## Features and bugs

Please file feature requests and bug reports at the [issue tracker][tracker].

[tracker]: http://github.com/imthedoctor/cryptsy-dart/issues
