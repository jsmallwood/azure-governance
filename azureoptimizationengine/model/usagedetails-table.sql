/****** Object:  Table [dbo].[UsageDetails]    Script Date: 4/24/2023 12:54:23 PM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UsageDetails]') AND type in (N'U'))
DROP TABLE [dbo].[UsageDetails]
GO

/****** Object:  Table [dbo].[UsageDetails]    Script Date: 4/24/2023 12:54:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UsageDetails](
	[PID] [int] IDENTITY(1,1) NOT NULL,
	[AccountName] [varchar](max) NULL,
	[AccountOwnerId] [varchar](128) NULL,
	[AdditionalInfo] [varchar](max) NULL,
	[BenefitId] [varchar](max) NULL,
	[BenefitName] [varchar](max) NULL,
	[BillingAccountId] [varchar](max) NULL,
	[BillingAccountName] [varchar](max) NULL,
	[BillingPeriodStartDate] [nvarchar](50) NULL,
	[BillingPeriodEndDate] [nvarchar](50) NULL,
	[BillingProfileId] [varchar](max) NULL,
	[BillingProfileName] [varchar](max) NULL,
	[ChargeType] [varchar](max) NULL,
	[ConsumedService] [varchar](max) NULL,
	[CostAllocationRuleName] [varchar](max) NULL,
	[Cost] [varchar](max) NULL,
	[Currency] [varchar](max) NULL,
	[Date] [datetime] NULL,
	[EffectivePrice] [money] NULL,
	[Frequency] [varchar](50) NULL,
	[InvoiceId] [varchar](max) NULL,
	[InvoiceSection] [varchar](max) NULL,
	[InvoiceSectionId] [varchar](max) NULL,
	[InvoiceSectionName] [varchar](max) NULL,
	[IsAzureCreditEligible] [varchar](10) NULL,
	[Location] [varchar](50) NULL,
	[MeterCategory] [varchar](max) NULL,
	[MeterId] [varchar](max) NULL,
	[MeterName] [varchar](max) NULL,
	[MeterRegion] [varchar](max) NULL,
	[MeterSubCategory] [varchar](max) NULL,
	[PayGPrice] [money] NULL,
	[PreviousInvoiceId] [varchar](max) NULL,
	[PricingModel] [varchar](max) NULL,
	[Product] [varchar](max) NULL,
	[ProductId] [varchar](max) NULL,
	[ProductOrderId] [varchar](max) NULL,
	[ProductOrderName] [varchar](max) NULL,
	[Provider] [varchar](max) NULL,
	[PublisherId] [varchar](max) NULL,
	[PublisherName] [varchar](max) NULL,
	[PublisherType] [varchar](max) NULL,
	[Quantity] [float] NULL,
	[ReservationId] [varchar](max) NULL,
	[ReservationName] [varchar](max) NULL,
	[ResourceGroup] [varchar](max) NULL,
	[ResourceId] [varchar](max) NULL,
	[ResourceLocation] [varchar](max) NULL,
	[ResourceName] [varchar](max) NULL,
	[RoundingAdjustment] [float] NULL,
	[ServiceFamily] [varchar](max) NULL,
	[ServiceInfo1] [varchar](max) NULL,
	[ServiceInfo2] [varchar](max) NULL,
	[ServicePeriodEndDate] [nvarchar](50) NULL,
	[ServicePeriodStartDate] [nvarchar](50) NULL,
	[SubscriptionId] [varchar](max) NULL,
	[SubscriptionName] [varchar](max) NULL,
	[Tags] [nvarchar](max) NULL,
	[Term] [varchar](10) NULL,
	[UnitOfMeasure] [varchar](50) NULL,
	[UnitPrice] [money] NULL,
 CONSTRAINT [PK_UsageDetails_ID] PRIMARY KEY CLUSTERED 
(
	[PID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


