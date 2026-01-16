WITH BaseSubset AS (

    SELECT
        i.InstallmentNumber,
        i.TransactionId,
        s.TransactionStatus,
        isx.InstallmentStatus,
        ist.InstallmentState,
        inv.ExpectedInvoiceDate,
        inv.PaymentTerms,
        pb.LeadAgents,
        cp.Buyer,
        cp.Seller,
        cp.Payer,
        o.OwnerGlobalId,
        it.InvoiceToName,
        r.RepresentationType,

        CASE
            WHEN r.RepresentationType IN ('Seller','Landlord') THEN cp.Seller
            WHEN r.RepresentationType IN ('Buyer','Tenant') THEN cp.Buyer
            WHEN r.RepresentationType = 'Both' THEN CONCAT(cp.Seller,' ; ',cp.Buyer)
            ELSE cp.Payer
        END AS RepresentationName,

        CONCAT(cp.Seller,' ; ',cp.Buyer,' ; ',cp.Payer) AS AccountName,
        dp.IsMultiRegion,
        d.DepartmentName,
        pt.PartyType,
        pr.Address,
        pr.City,
        pr.Region,
        pr.Country,
        t.ProjectName,
        inv.LegalDueDate,
        cur.CurrencyCode,
        i.AmountLocal,

        CASE
            WHEN i.StatusId = 8 AND fxh.TransactionLineId IS NOT NULL
                THEN i.AmountLocal * fxh.UsdRate
            WHEN i.StatusId <> 8 AND fxr.CurrencyCode = cur.CurrencyCode
                THEN i.AmountLocal * fxr.Rate
            ELSE i.AmountLocal
        END AS AmountUSD,

        inv.InvoiceNumber,
        inv.InvoiceDueDate,
        inv.InstallmentDueDate,
        i.PaymentPostedDate,
        i.PaymentAppliedDate,
        ag.DaysPastDue,

        CASE
            WHEN ag.DaysPastDue <= 0 THEN 'Current'
            WHEN ag.DaysPastDue <= 60 THEN '1-60'
            WHEN ag.DaysPastDue <= 90 THEN '61-90'
            WHEN ag.DaysPastDue <= 120 THEN '91-120'
            WHEN ag.DaysPastDue <= 180 THEN '121-180'
            WHEN ag.DaysPastDue <= 270 THEN '181-270'
            WHEN ag.DaysPastDue <= 365 THEN '271-365'
            ELSE '365+'
        END AS AgingBucket,

        ap.DaysToPay

    FROM FactInstallments i

    INNER JOIN DimDepartments d
        ON d.DepartmentId = i.DepartmentId
       AND d.DepartmentId IN (<department_id_list>)

    LEFT JOIN DimInstallmentStatus isx
        ON isx.StatusId = i.StatusId

    LEFT JOIN DimInstallments inv
        ON inv.InstallmentId = i.InstallmentId

    LEFT JOIN DimTransactions t
        ON t.TransactionId = i.TransactionId

    LEFT JOIN DimTransactionStatus s
        ON s.StatusId = t.StatusId

    LEFT JOIN DimParties pt
        ON pt.PartyTypeId = i.PartyTypeId

    LEFT JOIN DimClientsPivot cp
        ON cp.TransactionId = i.TransactionId

    LEFT JOIN DimLeadAgents pb
        ON pb.TransactionId = i.TransactionId

    LEFT JOIN DimProperties pr
        ON pr.TransactionId = i.TransactionId
       AND pr.IsPrimary = 1

    LEFT JOIN DimOwners o
        ON o.TransactionId = i.TransactionId

    LEFT JOIN DimInvoiceTo it
        ON it.PartyId = inv.InvoiceToId

    LEFT JOIN DimCurrencies cur
        ON cur.CurrencyId = i.CurrencyId

    LEFT JOIN FxRatesDaily fxr
        ON fxr.CurrencyCode = cur.CurrencyCode
       AND fxr.ToCurrency = 'USD'
       AND fxr.RateDate = CAST(GETDATE() - 1 AS DATE)

    LEFT JOIN FxRatesHistorical fxh
        ON fxh.TransactionLineId = i.TransactionLineId

    CROSS APPLY (
        SELECT
            CASE
                WHEN i.StatusId <> 8 AND inv.InvoiceDueDate IS NOT NULL
                    THEN DATEDIFF(DAY, inv.InvoiceDueDate, GETDATE())
                WHEN i.StatusId <> 8
                    THEN DATEDIFF(DAY, inv.InstallmentDueDate, GETDATE())
                ELSE NULL
            END
    ) ag (DaysPastDue)

    CROSS APPLY (
        SELECT
            CASE
                WHEN i.StatusId = 8
                    THEN DATEDIFF(DAY, inv.InstallmentDueDate, i.PaymentAppliedDate)
                ELSE NULL
            END
    ) ap (DaysToPay)

    WHERE
        i.IsDeleted = 0
        AND i.IsFinalRevenueInstallment = 1
        AND inv.LegalDueDate >= '2019-01-01'
        AND inv.LegalDueDate <  '2026-01-01'
        AND pt.PartyType = 'Agent'
        AND i.AmountLocal IS NOT NULL
)

SELECT *
FROM (
    /* Main broker-fee population */
    SELECT *
    FROM FactInstallments f
    WHERE f.TransactionId NOT IN (
        SELECT DISTINCT TransactionId FROM BaseSubset
    )

    UNION ALL

    /* Explicit inclusion of base subset */
    SELECT *
    FROM BaseSubset
) FinalResult;
