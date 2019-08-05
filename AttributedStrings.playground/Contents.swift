import Foundation
import UIKit

let quote = "Haters gonna hate"
let font = UIFont.systemFont(ofSize: 36)

let shadow = NSShadow()
shadow.shadowColor = UIColor.red
shadow.shadowBlurRadius = 5

let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center
paragraphStyle.firstLineHeadIndent = 5.0

var attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: UIColor.white,
    .shadow: shadow,
    //.paragraphStyle: paragraphStyle
]

let attributedQuote = NSAttributedString(string: quote, attributes: attributes) // Show results here

// To modify existing NSAttributedString: (now using NSMutableAttributedString)
let attributedQuote2 = NSMutableAttributedString(string: quote)
// make the word 'gonna' red:
attributedQuote2.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 7, length: 5)) // Show results here
// if multiple attributes at the same time wanted, use .addAttributes instead:
var attributes2: [NSAttributedString.Key: Any] = [
    .backgroundColor: UIColor.green,
    .kern: 10,
]
attributedQuote2.addAttributes(attributes2, range: NSRange(location: 0, length: 6)) // Show results here
// The autor of the article says, it is easier to create multiple independent attributed strings and then join them together:
let firstAttr: [NSAttributedString.Key: Any] = [
    .backgroundColor: UIColor.green,
    .kern: 10
]
let secondAttr: [NSAttributedString.Key: Any] = [
    .foregroundColor: UIColor.red
]

let firstString = NSMutableAttributedString(string: "Haters ", attributes: firstAttr)
let secondString = NSAttributedString(string: "gonna ", attributes: secondAttr)
let thirdString = NSAttributedString(string: "hate")

firstString.append(secondString)
firstString.append(thirdString) // Show results here
// i can then use NSMutableAttributedString to create normal attributed String (and to put it into the text field e.g.)
let attributedString = NSAttributedString(attributedString: firstString)



