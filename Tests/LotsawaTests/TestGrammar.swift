import Lotsawa

/// A `DefaultGrammar` that can be read from a string and that traffics in readable symbol names.
struct TestGrammar {
  /// Representation produced by Citron parser from the string.
  enum AST {
    typealias Token = TestGrammarToken
    typealias RuleList = [Rule]
    typealias Rule = (lhs: TestGrammarToken, alternatives: [RHS])
    typealias RHS = [Token]
  }

  /// The underlying raw grammar.
  var raw = DefaultGrammar()

  /// A mapping from raw grammar symbol to its name in the parsed source.
  var symbolName: [String] = []

  /// A mapping from symbol name in the parsed source to raw grammar symbol.
  var symbols: [String: Int] = [:]
}

extension TestGrammar {
  /// Creates an instance by parsing `bnf`, or throws an error if `bnf` can't be parsed.
  init(_ bnf: String, file: String = #filePath, line: Int = #line) throws {
    let tokens = testGrammarScanner.tokens(
      in: bnf, fromFile: file, unrecognizedToken: .ILLEGAL_CHARACTER)
    let parser = TestGrammarParser()
    for (id, text, position) in tokens {
      try parser.consume(token: TestGrammarToken(id, text, at: position), code: id)
    }
    let rules: AST.RuleList = try parser.endParsing()

    /// Translates t into a raw grammar symbol, memoizing name/symbol relationships.
    func demandSymbol(_ t: AST.Token) -> Int {
      let name = String(t.text)
      if let r = symbols[name] { return r }
      let id = symbolName.count
      symbols[name] = id
      symbolName.append(name)
      return id
    }

    for (lhsToken, alternatives) in rules {
      let lhs = demandSymbol(lhsToken)
      for a in alternatives {
        raw.addRule(lhs: lhs, rhs: a.map(demandSymbol))
      }
    }
  }
}

extension String {
  /// Returns the result of parsing `self` as a `TestGrammar`, or throws if `self` can't be parsed.
  func asTestGrammar(file: String = #filePath, line: Int = #line) throws -> TestGrammar {
    try TestGrammar(self, file: file, line: line)
  }
}

extension TestGrammar: CustomStringConvertible {
  /// Returns the human-readable name for `s`.
  func text(_ s: DefaultGrammar.Symbol) -> String { symbolName[s] }

  /// Returns a human-readable representation of `r`.
  func text(_ r: DefaultGrammar.Rule) -> String {
    text(r.lhs) + " ::= " + r.rhs.lazy.map { s in text(s) }.joined(separator: " ")
  }

  /// Returns the set of names of `s`'s elements.
  func text(_ s: Set<DefaultGrammar.Symbol>) -> Set<String> { Set(s.lazy.map(text)) }

  /// Returns a human-readable representation of `self`.
  var description: String {
    raw.rules.lazy.map { r in text(r) }.joined(separator: "\n")
  }
}
