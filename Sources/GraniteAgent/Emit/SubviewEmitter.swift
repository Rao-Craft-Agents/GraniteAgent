//  WHAT: A page's subview, alone in `Views/<Page>.<Role>View.swift`: a struct of values and optional closures, its
//        body from the host's model when the line describes it, or made from its value's fields when it does not
//        (a row, a cell, a detail), and a preview when the project has samples of its values.
//  PIN:  A CLOSURE IS OPTIONAL, AND ITS CONTROL HIDES WHEN THE PAGE GIVES NONE. A view never routes; a page that
//        cannot do something leaves the closure out, and the button is not drawn.

import Foundation

struct SubviewEmitter {
    let spec: ComponentSpec
    var describe: Describe { Describe(index: spec.index) }

    /// The view's whole file around `body`.
    func file(_ view: ViewSpec, body: String) -> String {
        var code = Code()
        var seen: Set<String> = []
        for module in ["Foundation", "SwiftUI"] + spec.imports where seen.insert(module).inserted { code.line("import \(module)") }
        code.line()
        code.line("/// \(doc(view))")
        code.open("struct \(spec.viewType(view)): View {")
        for value in view.values { code.line("let \(SwiftName.member(value.name)): \(value.type)") }
        for closure in view.closures {
            let type = closure.type.replacingOccurrences(of: "@escaping", with: "").trimmingCharacters(in: .whitespaces)
            code.line("var \(SwiftName.member(closure.name)): (\(type))? = nil")
        }
        code.line()
        code.open("var body: some View {")
        code.block(body)
        code.close()
        code.close()
        if let preview = preview(view) {
            code.line()
            code.block(preview)
        }
        return code.text
    }

    private func doc(_ view: ViewSpec) -> String {
        if let description = view.description { return SwiftName.sentence(description) }
        if let value = view.values.first { return "One \(SwiftName.words(value.type).lowercased()) as \(SwiftName.title(spec.type)) shows it." }
        return "Part of \(SwiftName.title(spec.type))."
    }

    /// `#Preview` with a sample of every value, when the project has one of each.
    private func preview(_ view: ViewSpec) -> String? {
        var arguments: [String] = []
        let enums = spec.index.types.filter { $0.value.kind == "enum" }.mapValues(\.cases)
        for value in view.values {
            guard let type = try? FieldLine.parseType(value.type, in: value.type),
                  let sample = Samples.value(type, previews: spec.index.previews, enums: enums) else { return nil }
            arguments.append("\(SwiftName.member(value.name)): \(sample)")
        }
        return "#Preview {\n    \(spec.viewType(view))(\(arguments.joined(separator: ", ")))\n        .padding()\n}"
    }

    // MARK: - Bodies made from fields

    /// A body for a view no one described: by its role and its value's fields.
    func body(_ view: ViewSpec) -> String {
        var main: String
        if view.values.count == 1, let value = view.values.first, spec.index.types[value.type]?.fields.isEmpty == false {
            let name = SwiftName.member(value.name)
            switch view.role {
            case "cell", "tile", "card": main = cell(name, value.type)
            case "content", "detail", "body", "page": main = content(name, value.type)
            default: main = row(name, value.type)
            }
        } else {
            main = generic(view)
        }
        let buttons = view.closures.filter { ComponentSpec.closureInputs($0.type).isEmpty }
        guard !buttons.isEmpty else { return main }
        var code = Code()
        code.open("VStack(alignment: .leading, spacing: 8) {")
        code.block(main)
        code.open("HStack(spacing: 16) {")
        for closure in buttons {
            let name = SwiftName.member(closure.name)
            var words = closure.name
            if words.hasPrefix("on"), words.count > 2, words.dropFirst(2).first?.isUppercase == true { words = String(words.dropFirst(2)) }
            code.line("if let \(name) { Button(\"\(SwiftName.escaped(SwiftName.title(words)))\") { \(name)() } }")
        }
        code.close()
        code.line(".buttonStyle(.borderless)")
        code.line(".font(.callout)")
        code.close()
        return trimmed(code)
    }

    /// One item in a list: a picture, its title, a line under it, a count and when.
    func row(_ value: String, _ type: String) -> String {
        let title = describe.title(of: type), subtitle = describe.subtitle(of: type, besides: title)
        var code = Code()
        code.open("HStack(alignment: .top, spacing: 12) {")
        if let image = describe.image(of: type) { thumbnail(&code, "\(value).\(image.name)", size: 44) }
        code.open("VStack(alignment: .leading, spacing: 4) {")
        text(&code, value, title, style: ".font(.headline)\n.lineLimit(2)")
        text(&code, value, subtitle, style: ".font(.subheadline)\n.foregroundStyle(.secondary)\n.lineLimit(3)")
        meta(&code, value, type)
        code.close()
        code.line("Spacer(minLength: 0)")
        code.close()
        code.line(".padding(.vertical, 4)")
        return trimmed(code)
    }

    /// One item in a grid: its picture on top, its title and a line under it, on a card.
    func cell(_ value: String, _ type: String) -> String {
        let title = describe.title(of: type), subtitle = describe.subtitle(of: type, besides: title)
        var code = Code()
        code.open("VStack(alignment: .leading, spacing: 8) {")
        if let image = describe.image(of: type) {
            code.line("AsyncImage(url: \(value).\(image.name)) { image in")
            code.line("    image.resizable().scaledToFill()")
            code.line("} placeholder: {")
            code.line("    Color.secondary.opacity(0.15)")
            code.line("}")
            code.line(".frame(height: 120)")
            code.line(".frame(maxWidth: .infinity)")
            code.line(".clipShape(RoundedRectangle(cornerRadius: 10))")
            code.line(".accessibilityHidden(true)")
        }
        text(&code, value, title, style: ".font(.headline)\n.lineLimit(2)")
        text(&code, value, subtitle, style: ".font(.caption)\n.foregroundStyle(.secondary)\n.lineLimit(2)")
        meta(&code, value, type)
        code.close()
        code.line(".frame(maxWidth: .infinity, alignment: .leading)")
        code.line(".padding(10)")
        code.line(".background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))")
        return trimmed(code)
    }

    /// One item on a page of its own: its picture, its title, its text, and its other fields labelled.
    func content(_ value: String, _ type: String) -> String {
        let title = describe.title(of: type), subtitle = describe.subtitle(of: type, besides: title), image = describe.image(of: type)
        var code = Code()
        code.open("VStack(alignment: .leading, spacing: 12) {")
        if let image {
            code.line("AsyncImage(url: \(value).\(image.name)) { image in")
            code.line("    image.resizable().scaledToFit()")
            code.line("} placeholder: {")
            code.line("    Color.secondary.opacity(0.15).frame(height: 200)")
            code.line("}")
            code.line(".frame(maxWidth: .infinity)")
            code.line(".clipShape(RoundedRectangle(cornerRadius: 12))")
            code.line(".accessibilityHidden(true)")
        }
        text(&code, value, title, style: ".font(.title2.bold())")
        text(&code, value, subtitle, style: ".font(.body)")
        let used = Set([title?.name, subtitle?.name, image?.name, "id"].compactMap { $0 })
        let others = describe.fields(of: type).filter { !used.contains($0.name) && isShowable($0.bare) }
        if !others.isEmpty {
            code.line("Divider()")
            for field in others { labelled(&code, value, field) }
        }
        code.close()
        return trimmed(code)
    }

    /// Values no one described and that are not one item: each shown by its type.
    func generic(_ view: ViewSpec) -> String {
        var code = Code()
        code.open("VStack(alignment: .leading, spacing: 4) {")
        for (index, value) in view.values.enumerated() {
            let name = SwiftName.member(value.name)
            let type = value.type.hasSuffix("?") ? String(value.type.dropLast()) : value.type
            let optional = value.type.hasSuffix("?")
            let shown = optional ? "shown" : name
            var lines: [String] = []
            switch type {
            case "String": lines = ["Text(\(shown))", index == 0 ? "    .font(.headline)" : "    .font(.subheadline)"] + (index == 0 ? [] : ["    .foregroundStyle(.secondary)"])
            case "Int", "Double": lines = ["Text(\(shown), format: .number)", "    .font(.caption)", "    .foregroundStyle(.secondary)"]
            case "Date": lines = ["Text(\(shown), format: .relative(presentation: .named))", "    .font(.caption)", "    .foregroundStyle(.secondary)"]
            case "URL": lines = ["Link(\(shown).absoluteString, destination: \(shown))", "    .font(.caption)"]
            default:
                if let title = describe.title(of: type) {
                    lines = ["Text(\(title.optional ? "\(shown).\(title.name) ?? \"\"" : "\(shown).\(title.name)"))", "    .font(.headline)"]
                }
            }
            guard !lines.isEmpty else { continue }
            if optional {
                code.scope("if let shown = \(name) {") { code in lines.forEach { code.line($0) } }
            } else {
                lines.forEach { code.line($0) }
            }
        }
        code.close()
        return trimmed(code)
    }

    // MARK: - Pieces

    private func thumbnail(_ code: inout Code, _ url: String, size: Int) {
        code.line("AsyncImage(url: \(url)) { image in")
        code.line("    image.resizable().scaledToFill()")
        code.line("} placeholder: {")
        code.line("    Color.secondary.opacity(0.15)")
        code.line("}")
        code.line(".frame(width: \(size), height: \(size))")
        code.line(".clipShape(RoundedRectangle(cornerRadius: 8))")
        code.line(".accessibilityHidden(true)")
    }

    /// A text field of the value, with its style; an optional one only when it has something.
    private func text(_ code: inout Code, _ value: String, _ field: Describe.Pick?, style: String) {
        guard let field else { return }
        let path = "\(value).\(SwiftName.member(field.name))"
        let styles = style.components(separatedBy: "\n").map { "    " + $0 }
        if field.optional {
            code.scope("if let \(field.name) = \(path) {") { code in
                code.line("Text(\(field.name))")
                styles.forEach { code.line($0) }
            }
        } else {
            code.line("Text(\(path))")
            styles.forEach { code.line($0) }
        }
    }

    /// A line of the value's count and when, in a caption.
    private func meta(_ code: inout Code, _ value: String, _ type: String) {
        let metric = describe.metric(of: type), date = describe.date(of: type)
        guard metric != nil || date != nil else { return }
        code.open("HStack(spacing: 12) {")
        if let metric {
            let symbol = Describe.symbol(for: metric.name)
            if metric.optional {
                code.line("if let \(metric.name) = \(value).\(metric.name) { Label(\(metric.name).formatted(), systemImage: \"\(symbol)\") }")
            } else {
                code.line("Label(\(value).\(metric.name).formatted(), systemImage: \"\(symbol)\")")
            }
        }
        if let date {
            if date.optional {
                code.line("if let \(date.name) = \(value).\(date.name) { Text(\(date.name), format: .relative(presentation: .named)) }")
            } else {
                code.line("Text(\(value).\(date.name), format: .relative(presentation: .named))")
            }
        }
        code.close()
        code.line(".font(.caption)")
        code.line(".foregroundStyle(.secondary)")
    }

    private func isShowable(_ type: String) -> Bool {
        ["Int", "Double", "String", "Date", "Bool", "URL", "[String]"].contains(type) || type.hasPrefix("[")
    }

    /// A field as a labelled row.
    private func labelled(_ code: inout Code, _ value: String, _ field: Describe.Pick) {
        let label = "\"\(SwiftName.escaped(SwiftName.title(field.name)))\""
        let path = field.optional ? field.name : "\(value).\(SwiftName.member(field.name))"
        var line: String
        switch field.bare {
        case "Int", "Double": line = "LabeledContent(\(label), value: \(path).formatted())"
        case "String": line = "LabeledContent(\(label), value: \(path))"
        case "Date": line = "LabeledContent(\(label)) { Text(\(path), format: .dateTime.day().month().year()) }"
        case "Bool": line = "LabeledContent(\(label)) { \(path) ? Text(\"Yes\") : Text(\"No\") }"
        case "URL": line = "LabeledContent(\(label)) { Link(\(path).absoluteString, destination: \(path)) }"
        case "[String]": line = "LabeledContent(\(label), value: \(path).joined(separator: \", \"))"
        default: line = "LabeledContent(\(label), value: \(path).count.formatted())"
        }
        if field.optional {
            code.scope("if let \(field.name) = \(value).\(SwiftName.member(field.name)) {") { $0.line(line) }
        } else {
            code.line(line)
        }
    }

    private func trimmed(_ code: Code) -> String {
        code.text.hasSuffix("\n") ? String(code.text.dropLast()) : code.text
    }
}
