import Testing
@testable import WhisperDictation

@Suite("KeycodeResolver")
struct KeycodeResolverTests {
    @Test("Resolver returns valid keycode")
    func resolverReturnsValidKeycode() {
        let resolver = KeycodeResolver()
        let keycode = resolver.keycode(for: "v")
        #expect(keycode < 128)
    }

    @Test("Resolver caching returns consistent results")
    func resolverCaching() {
        let resolver = KeycodeResolver()
        let first = resolver.keycode(for: "v")
        let second = resolver.keycode(for: "v")
        #expect(first == second)
    }

    @Test("Different characters have different keycodes")
    func differentCharacters() {
        let resolver = KeycodeResolver()
        let vCode = resolver.keycode(for: "v")
        let cCode = resolver.keycode(for: "c")
        #expect(vCode != cCode)
    }

    @Test("Fallback for unknown character")
    func fallbackForUnknownCharacter() {
        let resolver = KeycodeResolver()
        let keycode = resolver.keycode(for: "∞")
        // Should fall back to 0x09 (QWERTY V)
        #expect(keycode == 0x09)
    }

    @Test("Resolver creation")
    func resolverCreation() {
        let resolver = KeycodeResolver()
        #expect(resolver != nil)
    }
}
