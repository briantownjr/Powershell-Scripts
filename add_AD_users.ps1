#Import CSV of users and assign them to designated groups
#EXAMPLE of CSV:
#DisplayName,group
#testguy,testgroup
Import-Csv C:\Users\Administrator\Desktop\people.csv | %{
$name = $_.DisplayName
$SamAccountName = Get-ADUser -Filter{ name -like $name }|`

Add-ADGroupMember -Identity $_.group -Member $SamAccountName
}
