USE [PRP]
GO

/****** Object:  StoredProcedure [dbo].[qryInPRPItemHistTracking]    Script Date: 10/07/2019 10:12:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Michael J. Murray>
-- Create date: <1/4/2016>
-- Description:	<This report allows us to follow items sold by a specific vendor.>
-- =============================================
CREATE PROCEDURE [dbo].[qryInPRPItemHistTracking]
	-- Add the parameters for the stored procedure here
	@VendId varchar(10), 
	@Year smallint,
	@ItemId varchar(20) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	--SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>
	
IF @ItemId IS NULL
BEGIN	
	SELECT h.SumYear, h.SumPeriod, h.ItemId, CAST('' AS varchar(255)) AS Descr,
	SUM(h.QtyPurch) - SUM(h.QtyRetPurch) AS PurchasesInPeriod, SUM(h.QtySold) - SUM(h.QtyRetSold) as QtySoldInPeriod, CAST('0.00' AS decimal(10, 2)) AS cost--,
	--CAST('' AS varchar(50)) AS lAlias, CAST('' AS varchar(50)) AS sAlias
	INTO [#tmp1]
	FROM tblInHistSum AS h INNER JOIN
	(SELECT ItemId
	FROM tblInItemLocVend
	WHERE (VendId = @VendId)) AS v ON h.ItemId = v.ItemId INNER JOIN
	tblInItem AS i ON v.ItemId = i.ItemId
	WHERE (h.SumYear = @Year)
	GROUP BY h.SumYear, h.SumPeriod, h.ItemId

	---- Update temp tables
-- Update cost

	update t set t.cost = l.costlast
	from #tmp1 t inner join tblInItemLoc l
	on t.itemid = l.itemid

-- Update Decription

	update t set t.Descr = i.Descr + ' ' + CAST(CASE WHEN a.AddlDescr IS NULL THEN '' ELSE a.AddlDescr END AS varchar(255))
	from #tmp1 t inner join tblInItem i on t.itemid = i.itemid
	left join tblInItemAddlDescr a on i.itemid = a.itemid

-- update alias columns

--update t set t.lAlias = a.aliasid
--from #tmp t inner join tblInItemAlias a on t.itemid = a.itemid
--where LEFT(a.aliasid, charindex('-', a.aliasid)) = 'L-'

--update t set t.sAlias = a.aliasid
--from #tmp t inner join tblInItemAlias a on t.itemid = a.itemid
--where LEFT(a.aliasid, charindex('-', a.aliasid)) = 'S-'

-- combine results 

	select t.*,
	d.srceid, d.qty as CustomerQty,
	 c.region, c.country, c.custlevel 
	 from tblInHistDetail d inner join #tmp1 t 
	on d.itemid = t.itemid and d.sumyear = t.sumyear and d.sumperiod = t.sumperiod
	inner join tblArCust c on d.srceid = c.custid
	where t.PurchasesInPeriod + t.QtySoldInPeriod <> 0 and (d.TransType = 3 or d.transtype = 1) -- purchases and sales only!!
	order by d.itemid, d.sumperiod



end 
else

begin

IF @ItemId IS NOT NULL
BEGIN	

	SELECT h.SumYear, h.SumPeriod, h.ItemId, CAST('' AS varchar(255)) AS Descr,
	SUM(h.QtyPurch) - SUM(h.QtyRetPurch) AS PurchasesInPeriod, SUM(h.QtySold) - SUM(h.QtyRetSold) as QtySoldInPeriod, CAST('0.00' AS decimal(10, 2)) AS cost--,
	--CAST('' AS varchar(50)) AS lAlias, CAST('' AS varchar(50)) AS sAlias
	INTO [#tmp2]
	FROM tblInHistSum AS h 
	WHERE (h.SumYear = @Year) AND @ItemId = h.ItemId
	GROUP BY h.SumYear, h.SumPeriod, h.ItemId

	---- Update temp tables
-- Update cost

	update t set t.cost = l.costlast
	from #tmp2 t inner join tblInItemLoc l
	on t.itemid = l.itemid

-- Update Decription

	update t set t.Descr = i.Descr + ' ' + CAST(CASE WHEN a.AddlDescr IS NULL THEN '' ELSE a.AddlDescr END AS varchar(255))
	from #tmp2 t inner join tblInItem i on t.itemid = i.itemid
	left join tblInItemAddlDescr a on i.itemid = a.itemid

-- update alias columns

--update t set t.lAlias = a.aliasid
--from #tmp t inner join tblInItemAlias a on t.itemid = a.itemid
--where LEFT(a.aliasid, charindex('-', a.aliasid)) = 'L-'

--update t set t.sAlias = a.aliasid
--from #tmp t inner join tblInItemAlias a on t.itemid = a.itemid
--where LEFT(a.aliasid, charindex('-', a.aliasid)) = 'S-'

-- combine results 

	select t.*,
	d.srceid, d.qty as CustomerQty,
	 c.region, c.country, c.custlevel 
	 from tblInHistDetail d inner join #tmp2 t 
	on d.itemid = t.itemid and d.sumyear = t.sumyear and d.sumperiod = t.sumperiod
	inner join tblArCust c on d.srceid = c.custid
	where t.PurchasesInPeriod + t.QtySoldInPeriod <> 0 and (d.TransType = 3 or d.transtype = 1) -- purchases and sales only!!
	order by d.itemid, d.sumperiod



end



end	
	
END
GO

