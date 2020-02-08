class X2Character_DummyTarget extends X2Character;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_DummyTargetTemplate());

	return Templates;
}

static function X2CharacterTemplate Create_DummyTargetTemplate()
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Support_Strikes_Dummy_Target');

	CharTemplate.strPawnArchetypes.AddItem("GameUnit_MimicBeacon.ARC_MimicBeacon_M");
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_MimicBeacon.ARC_MimicBeacon_F");

	CharTemplate.UnitSize = 1;

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
	CharTemplate.DefaultLoadout = 'SupportStrikes_DummyTarget_Loadout';

	//CharTemplate.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');
	//CharTemplate.Abilities.AddItem('Ability_Support_Land_Off_StrafingRun_A10_Stage2');
	
	return CharTemplate;
}
/*

*/
/*
{
	local X2CharacterTemplate CharTemplate;

	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'Support_Strikes_Dummy_Target');	

	CharTemplate.BehaviorClass = class'XGAIBehavior';
	CharTemplate.strMatineePackages.AddItem("CIN_Turret");
	CharTemplate.strTargetingMatineePrefix = "CIN_Turret_FF_StartPos";

	CharTemplate.RevealMatineePrefix = "CIN_Turret_Tall";
	CharTemplate.strPawnArchetypes.AddItem("GameUnit_AdvTurret.ARC_GameUnit_AdvTurretM1");

	CharTemplate.CharacterBaseStats[eStat_AlertLevel]=2;
	CharTemplate.CharacterBaseStats[eStat_ArmorChance]=100;
	CharTemplate.CharacterBaseStats[eStat_ArmorMitigation]=2;
	CharTemplate.CharacterBaseStats[eStat_ArmorPiercing]=0;
	CharTemplate.CharacterBaseStats[eStat_CritChance]=0;
	CharTemplate.CharacterBaseStats[eStat_Defense]=0;
	CharTemplate.CharacterBaseStats[eStat_Dodge]=0;
	CharTemplate.CharacterBaseStats[eStat_HP]=8;
	CharTemplate.CharacterBaseStats[eStat_Mobility]=0;
	CharTemplate.CharacterBaseStats[eStat_Offense]=75;
	CharTemplate.CharacterBaseStats[eStat_PsiOffense]=0;
	CharTemplate.CharacterBaseStats[eStat_SightRadius]=27;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems]=1;
	CharTemplate.CharacterBaseStats[eStat_Will]=50;
	CharTemplate.CharacterBaseStats[eStat_HackDefense]=50;
	CharTemplate.CharacterBaseStats[eStat_FlankingCritChance]=50;
	CharTemplate.CharacterBaseStats[eStat_FlankingAimBonus]=0;
	CharTemplate.CharacterBaseStats[eStat_Strength]=50;

	CharTemplate.CharacterBaseStats[eStat_DetectionModifier]=1;	//	Cannot be seen (in concealment?)
	CharTemplate.CharacterBaseStats[eStat_DetectionRadius]=0;	//	Cannot see.
	

	// Traversal Rules
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
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bCanTakeCover = false;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = true;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsTurret = true;

	CharTemplate.UnitSize = 1;
	CharTemplate.VisionArcDegrees = 360;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;

	CharTemplate.bAllowSpawnFromATT = false;

	//	Kill the unit once Select 2 ability is cast so the unit no longer blocks tile
	CharTemplate.bBlocksPathingWhenDead = false;

	CharTemplate.ImmuneTypes.AddItem('Fire');
	CharTemplate.ImmuneTypes.AddItem('Poison');
	CharTemplate.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);
	CharTemplate.ImmuneTypes.AddItem('Panic');

	CharTemplate.strHackIconImage = "UILibrary_Common.TargetIcons.Hack_turret_icon";
	CharTemplate.strTargetIconImage = class'UIUtilities_Image'.const.TargetIcon_Turret;

	CharTemplate.bDisablePodRevealMovementChecks = true;

	CharTemplate.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');

	return CharTemplate;
}
*/
/*
*/