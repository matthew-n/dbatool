CREATE FUNCTION [Resources].[udft_parseUnicodeString]
--===== Define I/O parameters
        (@stringToParse NVARCHAR(4000), @delimiter NCHAR(1))
RETURNS TABLE WITH SCHEMABINDING AS
 RETURN
--===== "Inline" CTE Driven "Tally Table" produces values from 0 up to 10,000...
     -- enough to cover NVARCHAR(4000)
  WITH 
 cteTally(N) AS (--==== This provides the "base" CTE and limits the number of rows right up front
                     -- for both a performance gain and prevention of accidental "overruns"
                 SELECT TOP (ISNULL(DATALENGTH(@stringToParse)/2,0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM [Resources].[mediumTally]
                ),
cteStart(N1) AS (--==== This returns N+1 (starting position of each "element" just once for each delimiter)
                 SELECT 1 UNION ALL 
                 SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@stringToParse,t.N,1) = @delimiter
                ),
cteLen(N1,L1) AS(--==== Return start and length (for use in substring)
                 SELECT s.N1,
                        ISNULL(NULLIF(CHARINDEX(@delimiter,@stringToParse,s.N1),0)-s.N1,4000)
                   FROM cteStart s
                )
--===== Do the actual split. The ISNULL/NULLIF combo handles the length for the final element when no delimiter is found.
 SELECT ItemNumber = ROW_NUMBER() OVER(ORDER BY l.N1),
        Item       = SUBSTRING(@stringToParse, l.N1, l.L1)
   FROM cteLen l
;
GO
EXEC sp_addextendedproperty N'changelog', N'<revisionhist>
  <revision date="2010-01-20" version="00">
    <change>Base 10 redaction and reduction for CTE.  (Total rewrite)</change>
    <note>Concept for inline cteTally: Lynn Pettis and others. Redaction/Implementation: Jeff Moden</note>
  </revision>
  <revision date="2010-03-13" version="01" author="Jeff Moden">
    <change>Removed one additional concatenation and one subtraction from the SUBSTRING in the SELECT List for that tiny bit of extra speed.</change>
  </revision>
  <revision date="2010-04-14" version="02" author="Jeff Moden">
    <change> No code changes.  Added CROSS APPLY usage example to the header, some additional credits, and extra documentation.</change>
  </revision>
  <revision date="2010-04-18" version="03" author="Jeff Moden">
    <change>No code changes.  Added notes 7, 8, and 9 about certain "optimizations" that don''t actually work for this type of function.</change>
  </revision>
  <revision date="2010-06-29" version="04" author="Jeff Moden">
    <change>Added WITH SCHEMABINDING thanks to a note by Paul White.  This prevents an unnecessary "Table Spool" when the function is used in an UPDATE statement even though the function makes no external references.</change>
  </revision>
  <revision date="2011-04-02" version="05" author="Jeff Moden">
    <change>Rewritten for extreme performance improvement especially for larger strings approaching the 8K boundary and for strings that have wider elements.  The redaction of this code involved removing ALL concatenation of delimiters, optimization of the maximum "N" value by using TOP instead of including it in the WHERE clause, and the reduction of all previous calculations (thanks to the switch to a "zero based" cteTally) to just one instance of one add and one instance of a subtract. The length calculation for the final element (not followed by a delimiter) in the string to be split has been greatly simplified by using the ISNULL/NULLIF combination to determine when the CHARINDEX returned a 0 which indicates there are no more delimiters to be had or to start with. Depending on the width of the elements, this code is between 4 and 8 times faster on a single CPU box than the original code especially near the 8K boundary. </change>
    <change>Modified comments to include more sanity checks on the usage example, etc.</change>
    <change>Removed "other" notes 8 and 9 as they were no longer applicable.</change>
  </revision>
  <revision date="2011-04-12" version="06" author="Jeff Moden">
    <change>Based on a suggestion by Ron "Bitbucket" McCullough, additional test rows were added to the sample code and the code was changed to encapsulate the output in pipes so that spaces and empty strings could be perceived in the output.  The first "Notes" section was added.  Finally, an extra test was added to the comments above.</change>
  </revision>
  <revision date="2011-05-06" version="07" author="Jeff Moden">
    <change>Peter de Heer, a further 15-20% performance enhancement has been discovered and incorporated into this code which also eliminated the need for a "zero" position in the cteTally table.</change>
  </revision>
</revisionhist>', 'SCHEMA', N'Resources', 'FUNCTION', N'udft_parseUnicodeString', NULL, NULL
GO
EXEC sp_addextendedproperty N'credits', N'This code is the product of many people''s efforts including but not limited to the following:
 cteTally concept originally by Iztek Ben Gan and "decimalized" by Lynn Pettis (and others) for a bit of extra speed
 and finally redacted by Jeff Moden for a different slant on readability and compactness. Hat''s off to Paul White for
 his simple explanations of CROSS APPLY and for his detailed testing efforts. Last but not least, thanks to
 Ron "BitBucket" McCullough and Wayne Sheffield for their extreme performance testing across multiple machines and
 versions of SQL Server.  The latest improvement brought an additional 15-20% improvement over Rev 05.  Special thanks
 to "Nadrek" and "peter-757102" (aka Peter de Heer) for bringing such improvements to light.  Nadrek''s original
 improvement brought about a 10% performance gain and Peter followed that up with the content of Rev 07.  

 I also thank whoever wrote the first article I ever saw on "numbers tables" which is located at the following URL
 and to Adam Machanic for leading me to it many years ago.
 http://sqlserver2000.databases.aspfaq.com/why-should-i-consider-using-an-auxiliary-numbers-table.html', 'SCHEMA', N'Resources', 'FUNCTION', N'udft_parseUnicodeString', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Split a given string at a given delimiter and return a list of the split elements (items).', 'SCHEMA', N'Resources', 'FUNCTION', N'udft_parseUnicodeString', NULL, NULL
GO
EXEC sp_addextendedproperty N'notes', N' 1.  Leading a trailing delimiters are treated as if an empty string element were present.
 2.  Consecutive delimiters are treated as if an empty string element were present between them.
 3.  Except when spaces are used as a delimiter, all spaces present in each element are preserved.', 'SCHEMA', N'Resources', 'FUNCTION', N'udft_parseUnicodeString', NULL, NULL
GO
EXEC sp_addextendedproperty N'other_notes', N' 1. Optimized for NVARCHAR(4000) or less.  No testing or error reporting for truncation at 8000 characters is done.
 2. Optimized for single character delimiter.  Multi-character delimiters should be resolvedexternally from this 
    function.
 3. Optimized for use with CROSS APPLY.
 4. Does not "trim" elements just in case leading or trailing blanks are intended.
 5. If you don''t know how a Tally table can be used to replace loops, please see the following...
    http://www.sqlservercentral.com/articles/T-SQL/62867/
 6. Changing this function to use NVARCHAR(MAX) will cause it to run twice as slow.  It''s just the nature of 
    VARCHAR(MAX) whether it fits in-row or not.
 7. Multi-machine testing for the method of using UNPIVOT instead of 10 SELECT/UNION ALLs shows that the UNPIVOT method
    is quite machine dependent and can slow things down quite a bit.', 'SCHEMA', N'Resources', 'FUNCTION', N'udft_parseUnicodeString', NULL, NULL
GO
EXEC sp_addextendedproperty N'returns', N' iTVF containing the following:
 ItemNumber = Element position of Item as a BIGINT (not converted to INT to eliminate a CAST)
 Item       = Element value as a NVARCHAR(4000)', 'SCHEMA', N'Resources', 'FUNCTION', N'udft_parseUnicodeString', NULL, NULL
GO
