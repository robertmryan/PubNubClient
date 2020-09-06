## PubNub Client Demo

This is a demonstration of using PubNub to publish custom events for chat, namely:

* Publishing message events, including `new`, `update` and `delete` actions.
* Publishing read-receipt events.
* Publishing typing indicator signals.

Developed in Xcode 12.0 beta 6 (12A8189n). But it should work on any recent versions of Xcode.

BTW, this repo does not include my credentials in the form of:

```swift
struct PubNubCredentials {
    static let publishKey = "pub-..."
    static let subscribeKey = "sub-..."
}
```

So please supply your own `publishKey` and `subscribeKey` as outlined above, to get this mockup working. 

## License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.

--

6 September 2020

Copyright (c) 2020 Rob Ryan. All Rights Reserved.

See [License](LICENSE.md).
