-- Confirming that all rows of data have been uploaded from NashvilleHousing spreadsheet

SELECT 
*
FROM
PortfolioProject.dbo.NashvilleHousing


-- Changing the format of the 'sale date'.
-- Adding a new column with the desired date format

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateNewFormat varchar(10);


-- Copying the data from the existing column to the new column.

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateNewFormat = CONVERT(varchar, SaleDate, 105);


-- Dropping the existing column.

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate


-- Renaming the new column to the original name.

EXEC sp_rename 'PortfolioProject.dbo.NashvilleHousing.SaleDateNewFormat', 'SaleDate', 'COLUMN'; 


-- Identifying the rows where the PropertyAddress column contains NULL values. 

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID


-- As ParcelID corresponds with the PropertyAddress, this can be used to populate the Property Address for properties with NULL values where the Parcel ID matches.
--SELF JOIN: Joining the table to itself, if ParcelID a matches the ParcelID b, but the UniqueID is distinct, then populate the address value of ParcelID a (where there is a NULL value) with the address in ParcelID b (where there is no NULL value).

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


--Updating alias 'a' with the Property Address values from alias 'b'. 

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--Separating the Property Address into two distinct columns. 

SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) AS Address
FROM
PortfolioProject.dbo.NashvilleHousing


-- Creating two new columns for the new values. 

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyStreetAddress Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyCity Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


-- Separating the Owner Address into three distinct columns. 

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM
PortfolioProject.dbo.NashvilleHousing


--Creating three new columns for the new values. 

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerStreetAddress Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerCity Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerState Nvarchar(255); 

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


-- Viewing the number of rows which have incorrect lables in 'Sold as Vacant' field. 

SELECT 
DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM
PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant


--Changing Y and N to 'Yes' and 'No' in 'Sold as Vacant' field. 
-- Viewing the number of rows which have incorrect lables. 

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM
PortfolioProject.dbo.NashvilleHousing


--Updating the Table 

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


--Confirming that the table has been updated.

SELECT 
DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM
PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant


-- This query is generating a row number for each group of rows that have the same values in the specified columns, based on the order of the UniqueID column. This will help to identify duplicate rows.

WITH RowNumCTE AS(
SELECT *,
  ROW_NUMBER() OVER (
  PARTITION BY ParcelID,
             PropertyAddress, 
             SalePrice, 
             SaleDate,
             LegalReference 
             ORDER BY UniqueID
             ) row_num

FROM
PortfolioProject.dbo.NashvilleHousing
)


-- Delete duplicate rows.

DELETE
FROM RowNumCTE
WHERE row_num > 1
