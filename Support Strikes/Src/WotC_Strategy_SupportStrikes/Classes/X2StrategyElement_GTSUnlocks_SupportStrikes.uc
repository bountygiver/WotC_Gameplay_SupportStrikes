class X2StrategyElement_GTSUnlocks_SupportStrikes extends X2StrategyElement_AcademyUnlocks config (GameData_SupportStrikes);

struct ResourceCost
{
	var name	TemplateName;
	var int		Cost;
};

var config array<ResourceCost>	MortarStrike_HE_ResourceCost;


var config array<ResourceCost> MortarStrike_HE_ResourceCostStrategy;


var config array<ResourceCost> MortarStrike_SMK_ResourceCost;
var config array<ResourceCost> IonCannon_ResourceCost;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
		
	Templates.AddItem(GTSUnlock_Artillery_Off_MortarStrike_HE_T1());
	Templates.AddItem(GTSUnlock_Artillery_Def_MortarStrike_SMK_T1());

	Templates.AddItem(GTSUnlock_Orbital_Off_IonCannon_T1());

	return Templates;
}

static function X2SoldierAbilityUnlockTemplate GTSUnlock_Artillery_Off_MortarStrike_HE_T1()
{
	local X2SoldierAbilityUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'GTSUnlock_Artillery_Off_MortartStrike_HE_T1');

	Template.bAllClasses = true;
	Template.AbilityName = '';			//This unlock is a dummy. See X2EventListener_SupportStrikes, Line 79.
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

//	Template.Requirements.SpecialRequirementsFn = MortarStrikeEXPLRequirements;

	// Cost
	ModifyResourceCost(Template, default.MortarStrike_HE_ResourceCost);
	
	return Template;
}

static function X2SoldierAbilityUnlockTemplate GTSUnlock_Artillery_Def_MortarStrike_SMK_T1()
{
	local X2SoldierAbilityUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'GTSUnlock_Artillery_Def_MortartStrike_SMK_T1');

	Template.bAllClasses = true;
	Template.AbilityName = '';			//This unlock is a dummy. See X2EventListener_SupportStrikes, Line 79.
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

//	Template.Requirements.SpecialRequirementsFn = MortarStrikeSMKRequirements;

	// Cost
	ModifyResourceCost(Template, default.MortarStrike_SMK_ResourceCost);
	
	return Template;
}

static function X2SoldierAbilityUnlockTemplate GTSUnlock_Orbital_Off_IonCannon_T1()
{
	local X2SoldierAbilityUnlockTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'GTSUnlock_Orbital_Off_IonCannon_T1');

	Template.bAllClasses = true;
	Template.AbilityName = '';			//This unlock is a dummy. See X2EventListener_SupportStrikes, Line 79.
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

//	Template.Requirements.SpecialRequirementsFn = IonCannonStrikeProjectNotInProgress;

	// Cost
	ModifyResourceCost(Template, default.IonCannon_ResourceCost);
	
	return Template;
}

static function ModifyResourceCost(out X2SoldierAbilityUnlockTemplate Template, array<ResourceCost> ResourceCosts)
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
/*
static function bool MortarStrikeEXPLRequirements()
{
	return !GTSUnlockPurchased('GTSUnlock_Artillery_Def_MortartStrike_SMK_T1') && !StrikeProjectInProgress('Artillery');
}

static function bool MortarStrikeSMKRequirements()
{
	return !GTSUnlockPurchased('GTSUnlock_Artillery_Off_MortartStrike_HE_T1') && !StrikeProjectInProgress('Artillery');
}

static function bool IonCannonStrikeProjectNotInProgress()
{
	return !StrikeProjectInProgress('IonCannon');
}
*/
/*
static function bool StrikeProjectInProgress(name StrikeName)
{
	local XComGameStateHistory									History;
	local XComGameState_HeadquartersXCom						XComHQ;
	local XComGameState_HeadquartersProjectStrikeDelay			StrikeProject;
	local int													iProject;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	for (iProject = 0; iProject < XComHQ.Projects.Length; iProject++)
	{
		StrikeProject = XComGameState_HeadquartersProjectStrikeDelay(History.GetGameStateForObjectID(XComHQ.Projects[iProject].ObjectID));

		if (StrikeProject != none)
			if (StrikeProject.StrikeName == StrikeName)
				return true;
	}

	return false;
}
*/

static function bool GTSUnlockPurchased(name GTSUnlock)
{
	local XComGameState_HeadquartersXCom						XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if ( XComHQ.HasSoldierUnlockTemplate(GTSUnlock) )
		return true;

	return false;
}