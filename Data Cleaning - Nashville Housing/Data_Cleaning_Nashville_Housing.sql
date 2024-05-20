/*

Cleaning Data using PostgreSQL and pgAdmin 4

In this project I will be creating a proper table in a database in pgAdmin 4
that can receive the data from the Nasville Housing Dataset found on 
https://www.kaggle.com/datasets/tmthyjames/nashville-housing-data  

I will be commenting my code throughout the way
*/

--creating table with columns of correct type for the data to insert next

DROP TABLE  IF EXISTS Nashville_Housing;
CREATE TABLE Nashville_Housing (
	UniqueID INT,
	ParcelID VARCHAR (255),
	LandUse VARCHAR (255),
	PropertyAddress VARCHAR(255),
	SaleDate DATE,
	SalePrice VARCHAR (255),
	LegalReference VARCHAR (255),
	SoldAsVacant VARCHAR(50),
	OwnerName VARCHAR (255),
	OwnerAddress VARCHAR (255),
	Acreage NUMERIC,
	TaxDistrict VARCHAR (255),
	LandValue INT,
	BuildingValue INT,
	TotalValue INT,
	YearBuilt INT,
	Bedrooms INT,
	FullBath INT,
	HalfBath INT
);


--let's take a look to the dataset


SELECT * 
FROM Nashville_Housing;


/*After doing a revision of the dataset, first column with null values is 
the propertyadress column, so we will populate those nulls.

Notice that if parcelid is the same in two different rows, we can safely
assume that propertyaddress will be the same*/

SELECT *
FROM Nashville_Housing
ORDER BY parcelid;



--now let's try to populate null values, knowing that uniqueid is unique
--first we check it is working properly

SELECT 
	blank.parcelid, 
	blank.propertyaddress, 
	populated.parcelid, 
	populated.propertyaddress, 
	COALESCE (blank.propertyaddress, populated.propertyaddress) AS PopulatedPropertyAddress
FROM Nashville_Housing blank
JOIN Nashville_Housing populated
	ON blank.parcelid = populated.parcelid
	AND blank.uniqueid <> populated.uniqueid
WHERE blank.propertyaddress IS NULL
ORDER BY blank.parcelid;



--now we update the table 

UPDATE Nashville_Housing 
SET PropertyAddress = COALESCE (
		blank.propertyaddress, populated.propertyaddress)
FROM Nashville_Housing blank
JOIN Nashville_Housing populated
	ON blank.parcelid = populated.parcelid
	AND blank.uniqueid <> populated.uniqueid
WHERE blank.propertyaddress IS NULL;



-- break out Address column into individual columns (Address, City, State)
-- we will be using a substring to solve this, position and lenght to spot 
-- the comma and follow from it

SELECT PropertyAddress,
SUBSTRING (PropertyAddress, 1, POSITION (',' IN PropertyAddress)-1) AS Address,
SUBSTRING (PropertyAddress, POSITION (',' IN PropertyAddress)+1, 
		   	LENGTH (CAST(PropertyAddress AS text))) AS City 
FROM Nashville_Housing
ORDER BY parcelid;



--now we alter table and add new columns to it, and values obtained to them

ALTER TABLE Nashville_Housing
ADD PropertySplitAddress VARCHAR (255);

ALTER TABLE Nashville_Housing
ADD PropertySplitCity VARCHAR (255);

UPDATE Nashville_Housing
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, POSITION (',' IN PropertyAddress)-1);

UPDATE Nashville_Housing
SET PropertySplitCity = SUBSTRING (PropertyAddress, POSITION (',' IN PropertyAddress)+1, 
		   	LENGTH (CAST(PropertyAddress AS text)));



--split owneraddress in Address, City, State

SELECT 
  (REGEXP_SPLIT_TO_ARRAY(OwnerAddress, ','))[1] AS Address,
  (REGEXP_SPLIT_TO_ARRAY(OwnerAddress, ','))[2] AS City,
  (REGEXP_SPLIT_TO_ARRAY(OwnerAddress, ','))[3] AS State
FROM Nashville_Housing;



--now we alter table and add new columns to it, and values obtained to them

ALTER TABLE Nashville_Housing
ADD OwnerSplitAddress VARCHAR (255);

ALTER TABLE Nashville_Housing
ADD OwnerSplitCity VARCHAR (255);

ALTER TABLE Nashville_Housing
ADD OwnerSplitState VARCHAR (255);

UPDATE Nashville_Housing
SET OwnerSplitAddress = (REGEXP_SPLIT_TO_ARRAY(OwnerAddress, ','))[1];

UPDATE Nashville_Housing
SET OwnerSplitCity = (REGEXP_SPLIT_TO_ARRAY(OwnerAddress, ','))[2];

UPDATE Nashville_Housing
SET OwnerSplitState = (REGEXP_SPLIT_TO_ARRAY(OwnerAddress, ','))[3];




--soldasvacant column is not uniform, let's leave it with two values: Yes or No
--checking soldasvacant column

SELECT 
	DISTINCT (soldasvacant),
	COUNT(soldasvacant) AS YesOrNOCount
FROM Nashville_Housing
GROUP BY soldasvacant
ORDER BY YesOrNOCount;



--change values to just Yes and No using case statement

UPDATE Nashville_Housing
SET soldasvacant =
CASE
	WHEN soldasvacant = 'Y' THEN  'Yes'
	WHEN soldasvacant = 'N' THEN 'No'
	ELSE soldasvacant
	END;
	
SELECT * FROM Nashville_Housing


------------------------------------------------------
--find and remove duplicates and remove unused columns

WITH duplicates AS (
  SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
			     PropertyAddress, 
			     SalePrice,
			     SaleDate,
			     LegalReference
				ORDER BY
				parcelid) AS row_num
	FROM Nashville_Housing)
	
--this part of the code is for checking what we are about to remove

SELECT *
FROM duplicates
WHERE row_num > 1

	--Delete duplicate rows
-- this part actually removes the duplicates

DELETE FROM Nashville_Housing
WHERE (ParcelID,
	   PropertyAddress, 
	   SalePrice,
	   SaleDate,
	   LegalReference) 
	   IN (
			 SELECT  ParcelID,
					 PropertyAddress, 
					 SalePrice,
					 SaleDate,
					 LegalReference
			FROM duplicates
			WHERE row_num > 1
);
------------------------------------------------------

	
--delete unused columns
ALTER TABLE Nashville_Housing
	DROP COLUMN OwnerAddress, 
	DROP COLUMN TaxDistrict, 
	DROP COLUMN PropertyAddress;
	
