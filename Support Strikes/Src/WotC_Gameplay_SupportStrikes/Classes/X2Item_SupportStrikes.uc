class X2Item_SupportStrikes extends X2Item config(GameData_WeaponData);

var config WeaponDamageValue MortarStrike_HE_T1_BaseDamage;
var config int MortarStrike_HE_T1_EnvDamage;
var config int MortarStrike_HE_T1_Radius;
var config int MortarStrike_HE_T1_Quanitity;

var config WeaponDamageValue MortarStrike_SMK_T1_BaseDamage;
var config int MortarStrike_SMK_T1_EnvDamage;
var config int MortarStrike_SMK_T1_Radius;
var config int MortarStrike_SMK_T1_Quanitity;

var config WeaponDamageValue StrafingRun_A10_T1_BaseDamage;
var config int StrafingRun_A10_T1_EnvDamage;
var config int StrafingRun_A10_T1_Range;
var config int StrafingRun_A10_T1_Radius;
var config int StrafingRun_A10_T1_Quanitity;

var config WeaponDamageValue IonCannon_T1_BaseDamage;
var config int IonCannon_T1_EnvDamage;
var config int IonCannon_T1_Radius;
var config int IonCannon_T1_Quanitity;

//Should not have a damage value for heli drop in
var config WeaponDamageValue HeliDropIn_T1_BaseDamage;
var config int HeliDropIn_T1_EnvDamage;
var config int HeliDropIn_T1_Radius;
var config int HeliDropIn_T1_Quanitity;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Weapons;

	Weapons.AddItem(CreateSupport_Land_Offensive_MortarStrike_HE_T1_WPN());

	Weapons.AddItem(CreateSupport_Land_Defensive_MortarStrike_SMK_T1_WPN());

	Weapons.AddItem(CreateSupport_Air_Defensive_HeliDropIn_T1_WPN());

//  Weapons.AddItem(CreateSupport_Air_Offensive_StrafingRun_A10_T1_WPN());
//	Weapons.AddItem(CreateSupport_Air_Offensive_StrafingRun_A10_T1_WPN_Strike());

	Weapons.AddItem(CreateSupport_Space_Offensive_OrbitalStrike_IonCannon_T1_WPN());

	return Weapons;
}

static function X2DataTemplate CreateSupport_Land_Offensive_MortarStrike_HE_T1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Artillery_Offensive_MortarStrike_HE_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.MortarStrike_HE_T1_BaseDamage;
	Template.iClipSize = default.MortarStrike_HE_T1_Quanitity;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.MortarStrike_HE_T1_EnvDamage;
	Template.iRadius = default.MortarStrike_HE_T1_Radius;
	Template.iRange = 9999;
	Template.iPhysicsImpulse = 5;
//	Template.DamageTypeTemplateName = 'NoFireExplosion';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('Ability_Support_Land_Off_MortarStrike_HE_Stage1');
	Template.Abilities.AddItem('Ability_Support_Land_Off_MortarStrike_HE_Stage2');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_MortarStrike_CV";

	// Requirements
	Template.Requirements.SpecialRequirementsFn = No;

	return Template;
}


static function X2DataTemplate CreateSupport_Land_Defensive_MortarStrike_SMK_T1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Artillery_Defensive_MortarStrike_SMK_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.MortarStrike_SMK_T1_BaseDamage;
	Template.iClipSize = default.MortarStrike_SMK_T1_Quanitity;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.MortarStrike_SMK_T1_EnvDamage;
	Template.iRadius = default.MortarStrike_SMK_T1_Radius;
	Template.iRange = 9999;
	Template.iPhysicsImpulse = 5;
//	Template.DamageTypeTemplateName = 'NoFireExplosion';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('Ability_Support_Land_Def_MortarStrike_SMK_Stage1');
	Template.Abilities.AddItem('Ability_Support_Land_Def_MortarStrike_SMK_Stage2');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_MortarStrike_Smoke_CV";

	// Requirements
//	Template.Requirements.SpecialRequirementsFn = No;

	return Template;
}

static function X2DataTemplate CreateSupport_Air_Defensive_HeliDropIn_T1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Air_Defensive_HeliDropIn_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.HeliDropIn_T1_BaseDamage;
	Template.iClipSize = default.HeliDropIn_T1_Quanitity;
//	Template.iClipSize = 2;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.HeliDropIn_T1_EnvDamage;
	Template.iRadius = default.HeliDropIn_T1_Radius;
	Template.iRange = 9999;
	Template.iPhysicsImpulse = 0;
//	Template.DamageTypeTemplateName = 'NoFireExplosion';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('Ability_Support_Air_Def_HeliDropIn_Stage1');
	Template.Abilities.AddItem('Ability_Support_Air_Def_HeliDropIn_Stage2');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_HeliDropIn_CV";

	// Requirements
//	Template.Requirements.SpecialRequirementsFn = No;

	return Template;
}


/*
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_A10_T1_WPN()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Air_Offensive_StrafingRun_A10_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.StrafingRun_A10_T1_BaseDamage;
	Template.iClipSize = default.StrafingRun_A10_T1_Quanitity;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.StrafingRun_A10_T1_EnvDamage;
	Template.iRadius = 3;
	Template.iIdealRange = default.StrafingRun_A10_T1_Range;
	Template.iRange = 25;

	//	This range determines the targeting line length
	Template.iRange = 25;
	Template.iPhysicsImpulse = 5;
//	Template.DamageTypeTemplateName = 'NoFireExplosion';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectLocation');
	//Template.Abilities.AddItem('Ability_Support_Land_Off_StrafingRun_A10_Stage2');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_StrafingRun_A10_CV";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventTrooper');

	Template.CanBeBuilt = true;
	Template.PointsToComplete = 20;
	Template.TradingPostValue = 6;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 30;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
*/

//	This item is given to Dummy Target Unit
static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_A10_T1_WPN_Strike()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Air_Offensive_StrafingRun_A10_T1_Strike');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.StrafingRun_A10_T1_BaseDamage;
	Template.iClipSize = default.StrafingRun_A10_T1_Quanitity;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.StrafingRun_A10_T1_EnvDamage;
	Template.iRadius = default.StrafingRun_A10_T1_Radius;

	//	This range determines the targeting line length
	Template.iRange = 10;
	Template.iPhysicsImpulse = 5;
//	Template.DamageTypeTemplateName = 'NoFireExplosion';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectAngle');
	Template.Abilities.AddItem('Ability_Support_Land_Off_StrafingRun_A10_Stage2');

	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_StrafingRun_A10_CV";

	// Requirements
//	Template.Requirements.SpecialRequirementsFn = No;

	return Template;
}

static function X2DataTemplate CreateSupport_Space_Offensive_OrbitalStrike_IonCannon_T1_WPN()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Space_Offensive_IonCannon_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///uilibrary_strategyimages.X2InventoryIcons.Inv_Block";

	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.IonCannon_T1_BaseDamage;
	Template.iClipSize = default.IonCannon_T1_Quanitity;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.IonCannon_T1_EnvDamage;
	Template.iRadius = default.IonCannon_T1_Radius;
	Template.iRange = 9999;
	Template.iPhysicsImpulse = 5;
//	Template.DamageTypeTemplateName = 'NoFireExplosion';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('Ability_Support_Orbital_Off_IonCannon_Stage1');
	Template.Abilities.AddItem('Ability_Support_Orbital_Off_IonCannon_Stage2');


	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_IonCannon_BM";

	// Requirements
//	Template.Requirements.SpecialRequirementsFn = No;

	return Template;
}

static function bool No()
{
	return false;
}