class X2CharacterTemplate_SupportStrikes extends X2Character;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateDummyTargetingTemplate());

	return Templates;
}

static function X2CharacterTemplate CreateDummyTargetingTemplate()
{
	local X2CharacterTemplate CharTemplate;

	//PiS = Point in Space, not Piss
	`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'DummyPiSTarget');

	//Stat stuff
	CharTemplate.CharacterBaseStats[eStat_HP] = 1;
	CharTemplate.CharacterBaseStats[eStat_Offense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Defense] = 0;
	CharTemplate.CharacterBaseStats[eStat_Mobility] = 0;
	CharTemplate.CharacterBaseStats[eStat_SightRadius] = 1;
	CharTemplate.CharacterBaseStats[eStat_Will] = 50;
	CharTemplate.CharacterBaseStats[eStat_FlightFuel] = 0;
	CharTemplate.CharacterBaseStats[eStat_UtilityItems] = 1;
	CharTemplate.CharacterBaseStats[eStat_AlertLevel] = 2;
	CharTemplate.UnitSize = 1;

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = false;
	CharTemplate.bCanUse_eTraversal_BreakWindow = false;
	CharTemplate.bCanUse_eTraversal_KickDoor = false;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanUse_eTraversal_Launch = false;
	CharTemplate.bCanUse_eTraversal_Flying = false;
	CharTemplate.bCanUse_eTraversal_Land = true;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bIsAfraidOfFire = false;

	CharTemplate.bSkipDefaultAbilities = true;

	CharTemplate.bIsAlien = false;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = false;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;
	CharTemplate.bIsMeleeOnly = false;

	CharTemplate.bDisplayUIUnitFlag=false;
	CharTemplate.bAllowSpawnFromATT = false;
	CharTemplate.bNeverSelectable = false;

	//Abilities
	CharTemplate.Abilities.AddItem('DummyTargetInitialize');
	CharTemplate.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');


	//Pawn archetype
	CharTemplate.strPawnArchetypes.AddItem("ZZZ_SupportStrike_Data.Archetypes.ARC_GameUnit_DummyTarget");

	CharTemplate.bAllowRushCam = false;
	CharTemplate.SoloMoveSpeedModifier = 2.0f;

	return CharTemplate;
}