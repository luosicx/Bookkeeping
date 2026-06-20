import SwiftUI
import UIKit

class ReportExporter {
    @MainActor
    static func exportMonthlyReport(
        date: Date,
        transactions: [Transaction],
        currencyService: CurrencyService = .shared
    ) -> UIImage {
        let calendar = Calendar.current
        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
        
        let totalIncome = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let totalExpense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let balance = totalIncome - totalExpense
        
        let renderer = UIGraphicsImageRenderer(
            bounds: CGRect(x: 0, y: 0, width: 1080, height: 1920)
        )
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            let bgColor = UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0)
            bgColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1080, height: 1920))
            
            let headerGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
                UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0).cgColor,
                UIColor(red: 0.18, green: 0.45, blue: 0.78, alpha: 1.0).cgColor
            ] as CFArray, locations: [0, 1])!
            
            ctx.drawLinearGradient(headerGradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 1080, y: 300), options: [])
            
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.white
            ]
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "yyyy年M月"
            let title = "\(monthFormatter.string(from: date)) 收支报告"
            title.draw(at: CGPoint(x: 60, y: 80), withAttributes: titleAttrs)
            
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            "月度财务概览".draw(at: CGPoint(x: 60, y: 150), withAttributes: subtitleAttrs)
            
            drawStatCard(
                context: ctx,
                title: "收入",
                amount: currencyService.formatAmount(totalIncome, currency: currencyService.baseCurrency),
                color: UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0),
                at: CGPoint(x: 60, y: 340)
            )
            
            drawStatCard(
                context: ctx,
                title: "支出",
                amount: currencyService.formatAmount(totalExpense, currency: currencyService.baseCurrency),
                color: UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1.0),
                at: CGPoint(x: 380, y: 340)
            )
            
            drawStatCard(
                context: ctx,
                title: "结余",
                amount: currencyService.formatAmount(balance, currency: currencyService.baseCurrency),
                color: UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0),
                at: CGPoint(x: 700, y: 340)
            )
            
            drawCategorySummary(
                context: ctx,
                transactions: monthTransactions,
                currencyService: currencyService,
                at: CGPoint(x: 60, y: 560)
            )
            
            drawTransactionList(
                context: ctx,
                transactions: Array(monthTransactions.prefix(10)),
                currencyService: currencyService,
                at: CGPoint(x: 60, y: 1100)
            )
            
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.gray
            ]
            let footerText = "由 Bookkeeping 生成"
            let footerSize = (footerText as NSString).size(withAttributes: footerAttrs)
            footerText.draw(at: CGPoint(x: (1080 - footerSize.width) / 2, y: 1850), withAttributes: footerAttrs)
        }
    }
    
    private static func drawStatCard(context: CGContext, title: String, amount: String, color: UIColor, at point: CGPoint) {
        let cardWidth: CGFloat = 280
        let cardHeight: CGFloat = 180
        
        let path = UIBezierPath(roundedRect: CGRect(x: point.x, y: point.y, width: cardWidth, height: cardHeight), cornerRadius: 16)
        UIColor.white.setFill()
        path.fill()
        
        context.setShadow(offset: CGSize(width: 0, height: 4), blur: 8, color: UIColor.black.withAlphaComponent(0.1).cgColor)
        path.fill()
        context.setShadow(offset: .zero, blur: 0)
        
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24),
            .foregroundColor: UIColor.gray
        ]
        title.draw(at: CGPoint(x: point.x + 24, y: point.y + 24), withAttributes: titleAttrs)
        
        let amountAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 32),
            .foregroundColor: color
        ]
        amount.draw(at: CGPoint(x: point.x + 24, y: point.y + 80), withAttributes: amountAttrs)
    }
    
    private static func drawCategorySummary(context: CGContext, transactions: [Transaction], currencyService: CurrencyService, at point: CGPoint) {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 36),
            .foregroundColor: UIColor.black
        ]
        "分类支出".draw(at: point, withAttributes: titleAttrs)
        
        let expenseTransactions = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenseTransactions) { $0.category }
        let sorted = grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
        
        let colors: [UIColor] = [
            .systemOrange, .systemBlue, .systemPink, .systemPurple,
            .systemTeal, .systemRed, .systemGreen, .systemGray
        ]
        
        var yOffset = point.y + 60
        
        for (index, item) in sorted.prefix(8).enumerated() {
            let color = colors[index % colors.count]
            
            let dotRect = CGRect(x: point.x, y: yOffset + 8, width: 20, height: 20)
            let dotPath = UIBezierPath(ovalIn: dotRect)
            color.setFill()
            dotPath.fill()
            
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28),
                .foregroundColor: UIColor.black
            ]
            item.0.draw(at: CGPoint(x: point.x + 36, y: yOffset), withAttributes: nameAttrs)
            
            let amountAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.black
            ]
            let amountText = currencyService.formatAmount(item.1, currency: currencyService.baseCurrency)
            let amountSize = (amountText as NSString).size(withAttributes: amountAttrs)
            amountText.draw(at: CGPoint(x: 1020 - amountSize.width, y: yOffset), withAttributes: amountAttrs)
            
            yOffset += 56
        }
    }
    
    private static func drawTransactionList(context: CGContext, transactions: [Transaction], currencyService: CurrencyService, at point: CGPoint) {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 36),
            .foregroundColor: UIColor.black
        ]
        "最近交易".draw(at: point, withAttributes: titleAttrs)
        
        var yOffset = point.y + 60
        
        for transaction in transactions {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d"
            let dateText = dateFormatter.string(from: transaction.date)
            
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.gray
            ]
            dateText.draw(at: CGPoint(x: point.x, y: yOffset + 8), withAttributes: dateAttrs)
            
            let categoryAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28),
                .foregroundColor: UIColor.black
            ]
            transaction.category.draw(at: CGPoint(x: point.x + 100, y: yOffset + 4), withAttributes: categoryAttrs)
            
            let prefix = transaction.type == .income ? "+" : "-"
            let amountColor: UIColor = transaction.type == .income ? .systemGreen : .systemRed
            let amountAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: amountColor
            ]
            let amountText = "\(prefix)\(currencyService.formatAmount(transaction.amount, currency: currencyService.baseCurrency))"
            let amountSize = (amountText as NSString).size(withAttributes: amountAttrs)
            amountText.draw(at: CGPoint(x: 1020 - amountSize.width, y: yOffset + 4), withAttributes: amountAttrs)
            
            yOffset += 52
        }
    }
}
