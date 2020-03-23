class X2Character_SupportStrikes extends X2Character;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_DummyTargetTemplate());
//	Templates.AddItem(Create_SoldierResistanceSwarmTemplate('SoldierTrooperSwarm_T1'));
	Templates.AddItem(Create_XComTrooperRNFTestTemplate('SoldierTrooperTest_T1', 'XComTrooperRNFLoadoutT1' , "SoldierTrooperRNF::CharacterRoot", "XComTrooperRNFScamperRoot"));
	Templates.AddItem(Create_XComTrooperRNFTestTemplate('SoldierTrooperTest_T2', 'XComTrooperRNFLoadoutT2' , "SoldierTrooperRNF::CharacterRoot", "XComTrooperRNFScamperRoot"));
	Templates.AddItem(Create_XComTrooperRNFTestTemplate('SoldierTrooperTest_T3', 'XComTrooperRNFLoadoutT3' , "SoldierTrooperRNF::CharacterRoot", "XComTrooperRNFScamperRoot"));

	Templates.AddItem(Create_CineUnitCustomizableTemplate());
	return Templates;
}

static function X2CharacterTemplate Create_DummyTargetTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Support_Strikes_Dummy_Target');

//	CharTemplate.strPawnArchetypes.AddItem("GameUnit_MimicBeacon.ARC_MimicBeacon_M");
//	CharTemplate.strPawnArchetypes.AddItem("GameUnit_MimicBeacon.ARC_MimicBeacon_F");
	CharTemplate.strPawnArchetypes.AddItem("ZZZ_SupportStrike_Data.Archetypes.ARC_GameUnit_DummyTarget");
	CharTemplate.UnitSize = 1;
	CharTemplate.UnitHeight = 2;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsMeleeOnly = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;
	
	CharTemplate.bAllowSpawnFromATT = false;

	CharTemplate.bDisplayUIUnitFlag = false;

	CharTemplate.bNeverSelectable = false;

	//Leave a body at the very least for the stage 2 ability
	CharTemplate.bDontClearRemovedFromPlay = true;

	CharTemplate.DefaultLoadout = 'SupportStrikes_DummyTarget_Loadout';

	CharTemplate.Abilities.AddItem('DummyTargetInitialize');
//	CharTemplate.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');

	//CharTemplate.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');
	//CharTemplate.Abilities.AddItem('Ability_Support_Land_Off_StrafingRun_A10_Stage2');
	
	return CharTemplate;
}
/*
static function X2CharacterTemplate Create_SoldierResistanceSwarmTemplate(name TemplateName)
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);	
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior';
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeCriticallyWounded = true;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = true;
	CharTemplate.bCanTakeCover = true;
	CharTemplate.bCanBeCarried = true;	
	CharTemplate.bCanBeRevived = true;

	CharTemplate.strMatineePackages.AddItem("CIN_Soldier");
	CharTemplate.strIntroMatineeSlotPrefix = "Char";
	CharTemplate.strLoadingMatineeSlotPrefix = "Soldier";
	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.DefaultSoldierClass = 'Rookie';
	CharTemplate.DefaultLoadout = 'RookieSoldier';
	CharTemplate.RequiredLoadout = 'RequiredSoldier';
	CharTemplate.Abilities.AddItem('StandardMove');
	CharTemplate.Abilities.AddItem('Knockout');
	CharTemplate.Abilities.AddItem('KnockoutSelf');
	CharTemplate.Abilities.AddItem('Panicked');
	CharTemplate.Abilities.AddItem('Berserk');
	CharTemplate.Abilities.AddItem('Obsessed');
	CharTemplate.Abilities.AddItem('Shattered');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.Abilities.AddItem('DisableConsumeAllPoints');
	CharTemplate.Abilities.AddItem('Revive');
	
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_XCom;
	CharTemplate.strAutoRunNonAIBT = "SoldierAutoRunTree";
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}
*/
static function X2CharacterTemplate Create_XComTrooperRNFTestTemplate(name TemplateName, name LoadoutName, string strBehaviorTree, string strScamperBT)
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);	
	CharTemplate.CharacterGroupName = 'XComTrooperRNF';
	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior';

	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = true;
	CharTemplate.bCanTakeCover = true;
//	CharTemplate.bDisplayUIUnitFlag=false;
	CharTemplate.strMatineePackages.AddItem("CIN_Soldier");
	CharTemplate.strIntroMatineeSlotPrefix = "Char";
	CharTemplate.strLoadingMatineeSlotPrefix = "Soldier";

	CharTemplate.DefaultLoadout = LoadoutName;
	CharTemplate.Abilities.AddItem('Knockout');
	CharTemplate.Abilities.AddItem('KnockoutSelf');
	CharTemplate.Abilities.AddItem('Panicked');
	CharTemplate.Abilities.AddItem('Berserk');
	CharTemplate.Abilities.AddItem('Obsessed');
	CharTemplate.Abilities.AddItem('Shattered');
	CharTemplate.Abilities.AddItem('HunkerDown');
//	CharTemplate.Abilities.AddItem('DisableConsumeAllPoints');
	CharTemplate.Abilities.AddItem('Revive');

	CharTemplate.strPawnArchetypes.AddItem("GameUnit_XComSoldier.ARC_Soldier_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_XComSoldier.ARC_Soldier_F");

//	CharTemplate.MPPointValue = CharTemplate.XpKillscore * 10;

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Civilian;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	CharTemplate.bShouldCreateDifficultyVariants = false;

	CharTemplate.strBehaviorTree = strBehaviorTree;
	CharTemplate.strScamperBT = strScamperBT;

	return CharTemplate;
}

static function X2CharacterTemplate Create_CineUnitCustomizableTemplate(optional name TemplateName = 'CinematicUnit_Customizable')
{
	local X2CharacterTemplate CharTemplate;
	
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, TemplateName);

	CharTemplate.strPawnArchetypes.AddItem("GameUnit_XComSoldier.ARC_Soldier_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_XComSoldier.ARC_Soldier_F");
	
	CharTemplate.CharacterBaseStats[eStat_HP] = 5;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 6;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 14;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;

	CharTemplate.UnitSize = 1;
	CharTemplate.BehaviorClass = class'XGAIBehavior_Civilian';

	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = true;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = true;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = true;
	CharTemplate.bCanUse_eTraversal_DropDown = true;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;

	CharTemplate.bCanBeCarried = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = true;
	CharTemplate.bIsAfraidOfFire = true;
	CharTemplate.bIsAlien = false;
	CharTemplate.bIsCivilian = true;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bCanTakeCover = true;


	//If there is such a case this happens, don't spawn from ATT
	CharTemplate.bAllowSpawnFromATT = false;

	//Doesn't interact with the world outside of Matinees
	CharTemplate.bIsCosmetic = true;

	CharTemplate.Abilities.AddItem('Evac');
	CharTemplate.Abilities.AddItem('HunkerDown');
	CharTemplate.Abilities.AddItem('KnockoutSelf');
	CharTemplate.strBehaviorTree="VIPRoot";

	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_VIP;
	CharTemplate.CharacterGeneratorClass = class'XGCharacterGenerator';

	return CharTemplate;
}