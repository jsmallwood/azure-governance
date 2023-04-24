/****** Object:  StoredProcedure [dbo].[usp_InsertUsageDetails]    Script Date: 4/24/2023 12:55:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_InsertUsageDetails]
(
	@AccountName as varchar(max) = null,
	@AccountOwnerId as varchar(max) = null,
	@AdditionalInfo as varchar(max) = null,
	@BenefitId as varchar(max) = null,
	@BenefitName as varchar(max) = null,
	@BillingAccountId as varchar(max) = null,
	@BillingAccountName as varchar(max) = null,
	@BillingPeriodEndDate as nvarchar(50) = null,
	@BillingPeriodStartDate as nvarchar(50) = null,
	@BillingProfileId as varchar(max) = null,
	@BillingProfileName as varchar(max) = null,
	@ChargeType as varchar(max) = null,
	@ConsumedService as varchar(max) = null,
	@CostAllocationRuleName as varchar(max) = null,
	@Cost as money = null,
	@Currency as varchar(5) = null,
	@Date as datetime = null,
	@EffectivePrice as money = null,
	@Frequency as varchar(50) = null,
	@InvoiceId as varchar(max) = null,
	@InvoiceSection as varchar(max) = null,
	@InvoiceSectionId as varchar(max) = null,
	@InvoiceSectionName as varchar(max) = null,
	@IsAzureCreditEligible as varchar(10) = null,
	@Location as varchar(50) = null,
	@MeterCategory as varchar(max) = null,
	@MeterId as varchar(max) = null,
	@MeterName as varchar(max) = null,
	@MeterRegion as varchar(max) = null,
	@MeterSubCategory as varchar(max) = null,
	@PayGPrice as money = null,
	@PreviousInvoiceId as varchar(max) = null,
	@PricingModel as varchar(max) = null,
	@Product as varchar(max) = null,
	@ProductId as varchar(max) = null,
	@ProductOrderId as varchar(max) = null,
	@ProductOrderName as varchar(max) = null,
	@Provider as varchar(max) = null,
	@PublisherId as varchar(max) = null,
	@PublisherName as varchar(max) = null,
	@PublisherType as varchar(max) = null,
	@Quantity as float = null,
	@ReservationId as varchar(max) = null,
	@ReservationName as varchar(max) = null,
	@ResourceGroup as varchar(max) = null,
	@ResourceId as varchar(max) = null,
	@ResourceLocation as varchar(max) = null,
	@ResourceName as varchar(max) = null,
	@RoundingAdjustment as float = null,
	@ServiceFamily as varchar(max) = null,
	@ServiceInfo1 as varchar(max) = null,
	@ServiceInfo2 as varchar(max) = null,
	@ServicePeriodStartDate as nvarchar(50) = null,
	@ServicePeriodEndDate as nvarchar(50) = null,
	@SubscriptionId as varchar(max) = null,
	@SubscriptionName as varchar(max) = null,
	@Tags as nvarchar(max) = null,
	@Term as varchar(10) = null,
	@UnitOfMeasure as varchar(50) = null,
	@UnitPrice as money = null
)
AS

BEGIN

	SET NOCOUNT ON
	IF NOT EXISTS(SELECT 1 FROM [dbo].[UsageDetails] WHERE Date=@Date and ChargeType = @ChargeType and Cost = @Cost and MeterId = @MeterId and MeterName = @MeterName and ProductId = @ProductId and ResourceId = @ResourceId and UnitPrice = @UnitPrice)
		BEGIN
			INSERT INTO [dbo].[UsageDetails] 
			(AccountName, AccountOwnerId, AdditionalInfo, BenefitId, BenefitName, BillingAccountId, BillingAccountName, BillingPeriodStartDate, BillingPeriodEndDate, BillingProfileId, BillingProfileName, ChargeType, ConsumedService, CostAllocationRuleName, Cost, Currency, 
	Date, EffectivePrice, Frequency, InvoiceId, InvoiceSection, InvoiceSectionId, InvoiceSectionName, IsAzureCreditEligible, Location, MeterCategory, 
	MeterId, MeterName, MeterRegion, MeterSubCategory, PayGPrice, PreviousInvoiceId, PricingModel, Product, ProductId, ProductOrderId, 
	ProductOrderName, Provider, PublisherId, PublisherName, PublisherType, Quantity, ReservationId, ReservationName, ResourceGroup, 
	ResourceId, ResourceLocation, ResourceName, RoundingAdjustment, ServiceFamily, ServiceInfo1, ServiceInfo2, ServicePeriodEndDate, 
	ServicePeriodStartDate, SubscriptionId, SubscriptionName, Tags, Term, UnitOfMeasure, UnitPrice)
			VALUES (@AccountName, @AccountOwnerId, @AdditionalInfo, @BenefitId, @BenefitName, @BillingAccountId, @BillingAccountName, @BillingPeriodStartDate, 
	@BillingPeriodEndDate, @BillingProfileId, @BillingProfileName, @ChargeType,	@ConsumedService, @CostAllocationRuleName, @Cost, @Currency, 
	@Date, @EffectivePrice, @Frequency, @InvoiceId, @InvoiceSection, @InvoiceSectionId, @InvoiceSectionName, @IsAzureCreditEligible, @Location, @MeterCategory, 
	@MeterId, @MeterName, @MeterRegion, @MeterSubCategory, @PayGPrice, @PreviousInvoiceId, @PricingModel, @Product, @ProductId, @ProductOrderId, 
	@ProductOrderName, @Provider, @PublisherId, @PublisherName, @PublisherType, @Quantity, @ReservationId, @ReservationName, @ResourceGroup, 
	@ResourceId, @ResourceLocation, @ResourceName, @RoundingAdjustment, @ServiceFamily, @ServiceInfo1, @ServiceInfo2, @ServicePeriodEndDate, 
	@ServicePeriodStartDate, @SubscriptionId, @SubscriptionName, @Tags, @Term, @UnitOfMeasure, @UnitPrice)
		END
END
GO
