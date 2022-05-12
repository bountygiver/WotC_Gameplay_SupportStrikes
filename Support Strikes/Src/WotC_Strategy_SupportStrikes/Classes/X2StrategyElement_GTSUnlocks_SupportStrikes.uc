class X2StrategyElement_GTSUnlocks_SupportStrikes extends X2StrategyElement_AcademyUnlocks config (GameData_SupportStrikes);

struct ResourceCost
{
	var name	TemplateName;
	var int		Cost;
};

var config array<ResourceCost>	MortarStrike_HE_ResourceCost;
var config array<ResourceCost>	MortarStrike_SMK_ResourceCost;
var config array<ResourceCost>	Recon_T1_ResourceCost;
var config array<ResourceCost>	HeliDropIn_ResourceCost;
var config array<ResourceCost>	StrafingRun_A10_ResourceCost;
var config array<ResourceCost>	IonCannon_ResourceCost;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	//Stationary Weapon Platforms
	Templates.AddItem(GTSUnlock_Artillery_Off_MortarStrike_HE_T1());
	Templates.AddItem(GTSUnlock_Artillery_Def_MortarStrike_SMK_T1());

	//Air-to-Ground or General Aircraft Supports
	Templates.AddItem(GTSUnlock_Airborne_Def_HeliDropIn_T1());
	//Templates.AddItem(GTSUnlock_Airborne_Def_AWACS_T1());
	Templates.AddItem(GTSUnlock_Airborne_Off_StrafingRun_A10_T1());
	//Orbital Weapon Platforms
	Templates.AddItem(GTSUnlock_Orbital_Off_IonCannon_T1());

	return Templates;
}

static function X2SupportStrikeUnlockTemplate GTSUnlock_Artillery_Off_MortarStrike_HE_T1()
{
	local X2SupportStrikeUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SupportStrikeUnlockTemplate', Template, 'GTSUnlock_Artillery_Off_MortartStrike_HE_T1');

	Template.bAllClasses = true;
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.AbilityName = 'Ability_Support_Land_Off_MortarStrike_HE_Stage1';

	// Cost
	ModifyResourceCost(Template, default.MortarStrike_HE_ResourceCost);
	
	return Template;
}

static function X2SupportStrikeUnlockTemplate GTSUnlock_Artillery_Def_MortarStrike_SMK_T1()
{
	local X2SupportStrikeUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SupportStrikeUnlockTemplate', Template, 'GTSUnlock_Artillery_Def_MortartStrike_SMK_T1');

	Template.bAllClasses = true;
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.AbilityName = 'Ability_Support_Land_Def_MortarStrike_SMK_Stage1';

	// Cost
	ModifyResourceCost(Template, default.MortarStrike_SMK_ResourceCost);
	
	return Template;
}

static function X2SupportStrikeUnlockTemplate GTSUnlock_Airborne_Def_AWACS_T1()
{
	local X2SupportStrikeUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SupportStrikeUnlockTemplate', Template, 'GTSUnlock_Airborne_Def_AWACS_T1');

	Template.bAllClasses = true;
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.AbilityName = 'Ability_Support_Airborne_Def_Recon_T1_Stage1';

	// Cost
	ModifyResourceCost(Template, default.HeliDropIn_ResourceCost);
	
	return Template;
}

static function X2SupportStrikeUnlockTemplate GTSUnlock_Airborne_Def_HeliDropIn_T1()
{
	local X2SupportStrikeUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SupportStrikeUnlockTemplate', Template, 'GTSUnlock_Airborne_Def_HeliDropIn_T1');

	Template.bAllClasses = true;
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.AbilityName = 'Ability_Support_Air_Def_HeliDropIn_Stage1';

	// Cost
	ModifyResourceCost(Template, default.HeliDropIn_ResourceCost);
	
	return Template;
}

static function X2SupportStrikeUnlockTemplate GTSUnlock_Airborne_Off_StrafingRun_A10_T1()
{
	local X2SupportStrikeUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SupportStrikeUnlockTemplate', Template, 'GTSUnlock_Airborne_Off_PrecisionStrike_A10_T1');

	Template.bAllClasses = true;
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.AbilityName = 'Ability_Support_Air_Off_StrafingRun_A10_Stage1';

	// Cost
	ModifyResourceCost(Template, default.StrafingRun_A10_ResourceCost);
	
	return Template;
}

static function X2SupportStrikeUnlockTemplate GTSUnlock_Orbital_Off_IonCannon_T1()
{
	local X2SupportStrikeUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SupportStrikeUnlockTemplate', Template, 'GTSUnlock_Orbital_Off_IonCannon_T1');

	Template.bAllClasses = true;
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.AbilityName = 'Ability_Support_Orbital_Off_IonCannon_Stage1';

	// Cost
	ModifyResourceCost(Template, default.IonCannon_ResourceCost);
	
	return Template;
}

static function ModifyResourceCost(out X2SupportStrikeUnlockTemplate Template, array<ResourceCost> ResourceCosts)
{
	local ArtifactCost Resources;
	local ResourceCost IndividualCost;
	
	foreach ResourceCosts(IndividualCost)
	{
		Resources.ItemTemplateName	= IndividualCost.TemplateName;
		Resources.Quantity			= IndividualCost.Cost;
		Template.Cost.ResourceCosts.AddItem(Resources);
	}
}