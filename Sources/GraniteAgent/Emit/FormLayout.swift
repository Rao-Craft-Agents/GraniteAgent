//  WHAT: The form family's `+View`: a grouped form whose rows are the shows lines a label each, in their sections.
//        A row bound to something a control may write is a control chosen by the type (a toggle, a field, a stepper,
//        a picker over an enum's cases, a date picker); anything else is shown as it is. Settings end with their
//        buttons; a form sends with its submit; a compose page sends and closes, or cancels.

import Foundation

struct FormLayout {
    let emitter: ComponentEmitter
    var spec: ComponentSpec { emitter.spec }

    func body(_ code: inout Code) {
        code.open("var view: some View {")
        code.open("Form {")
        var sections: [(name: String?, rows: [Show])] = []
        for show in spec.labelled {
            guard case .label(let section, _) = show.key else { continue }
            if let index = sections.firstIndex(where: { $0.name == section }) { sections[index].rows.append(show) } else { sections.append((section, [show])) }
        }
        for section in sections {
            code.open(section.name.map { "Section(\"\(SwiftName.escaped($0))\") {" } ?? "Section {")
            for row in section.rows { control(&code, row) }
            code.close()
        }
        let buttons = spec.toolbarActions
        if spec.layout == .settings, !buttons.isEmpty {
            code.scope("Section {") { code in
                for action in buttons { code.line(emitter.button(action, item: nil)) }
            }
        }
        if spec.layout == .form, let submit = spec.submit {
            code.scope("Section {") { code in
                code.line("Button(\"\(SwiftName.escaped(submit.label))\") { \(spec.call(submit)) }")
                if let disabled = disabledCondition { code.line("    .disabled(\(disabled))") }
            }
        }
        code.close()
        code.line(".formStyle(.grouped)")
        if spec.errorExpression != nil { code.line(".safeAreaInset(edge: .top, spacing: 0) { errorBanner }") }
        code.line(spec.titleModifier)
        if spec.layout == .compose {
            var extra: [String] = []
            extra.append("ToolbarItem(placement: .cancellationAction) {\n    Button(\"Cancel\") { dismiss() }\n}")
            if let submit = spec.submit {
                var confirm = "ToolbarItem(placement: .confirmationAction) {\n    Button(\"\(SwiftName.escaped(submit.label))\") {\n        Task { if (try? await \(SwiftName.member(submit.name))()) != nil { dismiss() } }\n    }"
                if let disabled = disabledCondition { confirm += "\n    .disabled(\(disabled))" }
                confirm += "\n}"
                extra.append(confirm)
            }
            emitter.toolbar(&code, extra: extra)
        } else if spec.layout == .form {
            emitter.toolbar(&code)
        }
        code.close()
        emitter.errorBanner(&code)
    }

    /// Why the send button waits: work in flight, or the first text field left empty.
    private var disabledCondition: String? {
        var conditions: [String] = []
        if let loading = spec.loadingExpression { conditions.append(loading) }
        let firstText = spec.labelled.first { show in
            emitter.ownField(show.expression)?.type == .named("String")
        }
        if let firstText { conditions.append("\(firstText.expression).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty") }
        return conditions.isEmpty ? nil : conditions.joined(separator: " || ")
    }

    /// One row: a control when something may be written, the value as it is otherwise.
    private func control(_ code: inout Code, _ show: Show) {
        guard case .label(_, let text) = show.key else { return }
        let label = "\"\(SwiftName.escaped(text))\""
        let expression = show.expression
        let type = emitter.typeRef(expression)
        if let binding = emitter.binding(expression), let type, !type.isOptional, case .named(let name) = type {
            switch name {
            case "Bool":
                code.line("Toggle(\(label), isOn: \(binding))")
                return
            case "String":
                if Self.isLong(text) || Self.isLong(expression) {
                    code.line("TextField(\(label), text: \(binding), axis: .vertical)")
                    code.line("    .lineLimit(4...12)")
                } else {
                    code.line("TextField(\(label), text: \(binding))")
                }
                return
            case "Int":
                code.scope("Stepper(value: \(binding)) {") { $0.line("LabeledContent(\(label), value: \(expression).formatted())") }
                return
            case "Double":
                code.line("TextField(\(label), value: \(binding), format: .number)")
                return
            case "Date":
                code.line("DatePicker(\(label), selection: \(binding))")
                return
            default:
                if let info = spec.index.types[name], info.kind == "enum", info.isCaseIterable {
                    code.scope("Picker(\(label), selection: \(binding)) {") { code in
                        let each = info.conformances.contains("Identifiable") ? "ForEach(\(name).allCases) { option in" : "ForEach(\(name).allCases, id: \\.self) { option in"
                        code.scope(each) { code in
                            code.line(info.hasTitle ? "Text(option.title).tag(option)" : "Text(verbatim: String(describing: option).capitalized).tag(option)")
                        }
                    }
                    return
                }
            }
        }
        display(&code, label: label, expression: expression, type: type)
    }

    /// A value shown as it is, by its type.
    private func display(_ code: inout Code, label: String, expression: String, type: TypeRef?) {
        guard let type else { code.line("LabeledContent(\(label), value: String(describing: \(expression)))"); return }
        let name = type.unwrapped.description
        if type.isOptional {
            code.scope("if let value = \(expression) {") { code in
                display(&code, label: label, expression: "value", type: type.unwrapped)
            }
            return
        }
        switch name {
        case "Int", "Double", "Int64", "Float", "CGFloat": code.line("LabeledContent(\(label), value: \(expression).formatted())")
        case "String": code.line("LabeledContent(\(label), value: \(expression))")
        case "Date": code.line("LabeledContent(\(label)) { Text(\(expression), format: .dateTime.day().month().year().hour().minute()) }")
        case "Bool": code.line("LabeledContent(\(label)) { \(expression) ? Text(\"On\") : Text(\"Off\") }")
        case "URL": code.line("LabeledContent(\(label)) { Link(\(expression).absoluteString, destination: \(expression)) }")
        default:
            if let info = spec.index.types[name], info.hasTitle {
                code.line("LabeledContent(\(label), value: \(expression).title)")
            } else if type.element != nil {
                code.line("LabeledContent(\(label), value: \(expression).count.formatted())")
            } else {
                code.line("LabeledContent(\(label), value: String(describing: \(expression)))")
            }
        }
    }

    /// Whether a field holds more than a line: its name says it is a body of text.
    static func isLong(_ text: String) -> Bool {
        let lower = text.lowercased()
        return ["body", "text", "notes", "description", "content", "message", "bio", "summary", "comment", "details"].contains { lower.contains($0) }
    }
}
