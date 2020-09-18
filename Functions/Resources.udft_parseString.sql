CREATE FUNCTION [Resources].[udft_parseString]
--===== Define I/O parameters
        (@stringToParse VARCHAR(8000), @delimiter CHAR(1))
RETURNS TABLE WITH SCHEMABINDING AS
 RETURN
--===== "Inline" CTE Driven "Tally Table" produces values from 0 up to 10,000...
     -- enough to cover NVARCHAR(4000)
  WITH 
 cteTally(N) AS (--==== This provides the "base" CTE and limits the number of rows right up front
                     -- for both a performance gain and prevention of accidental "overruns"
                 SELECT TOP (ISNULL(DATALENGTH(@stringToParse),0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM [Resources].[mediumTally]
                ),
cteStart(N1) AS (--==== This returns N+1 (starting position of each "element" just once for each delimiter)
                 SELECT 1 UNION ALL 
                 SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@stringToParse,t.N,1) = @delimiter
                ),
cteLen(N1,L1) AS(--==== Return start and length (for use in substring)
                 SELECT s.N1,
                        ISNULL(NULLIF(CHARINDEX(@delimiter,@stringToParse,s.N1),0)-s.N1,8000)
                   FROM cteStart s
                )
--===== Do the actual split. The ISNULL/NULLIF combo handles the length for the final element when no delimiter is found.
 SELECT ItemNumber = ROW_NUMBER() OVER(ORDER BY l.N1),
        Item       = SUBSTRING(@stringToParse, l.N1, l.L1)
   FROM cteLen l
;
GO
