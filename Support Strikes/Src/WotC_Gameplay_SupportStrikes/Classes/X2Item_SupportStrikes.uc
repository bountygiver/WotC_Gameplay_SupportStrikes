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
var config int StrafingRun_A10_T1_Radius;
var config int StrafingRun_A10_T1_Quanitity;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Weapons;

	Weapons.AddItem(CreateSupport_Land_Offensive_MortarStrike_HE_T1_WPN());

	Weapons.AddItem(CreateSupport_Land_Defensive_MortarStrike_SMK_T1_WPN());

	Weapons.AddItem(CreateSupport_Air_Offensive_StrafingRun_A10_T1_WPN());

	return Weapons;
}

static function X2DataTemplate CreateSupport_Land_Offensive_MortarStrike_HE_T1_WPN()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Artillery_Offensive_MortarStrike_HE_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ArchonStaff";

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
//	Template.Abilities.AddItem('Ability_Support_Land_Off_MortarStrike_HE_Stage2');


	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_MortarStrike_CV";

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


static function X2DataTemplate CreateSupport_Land_Defensive_MortarStrike_SMK_T1_WPN()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Artillery_Defensive_MortarStrike_SMK_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ArchonStaff";

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
//	Template.Abilities.AddItem('Ability_Support_Land_Off_MortarStrike_HE_Stage2');


	// This all the resources; sounds, animations, models, physics, the works.
	Template.GameArchetype = "ZZZ_SupportStrike_Data.Archetypes.WP_MortarStrike_CV";

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


static function X2DataTemplate CreateSupport_Air_Offensive_StrafingRun_A10_T1_WPN()
{
	local X2WeaponTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Support_Air_Offensive_StrafingRun_A10_T1');
	
	Template.WeaponPanelImage = "_ConventionalRifle";                       // used by the UI. Probably determines iconview of the weapon.
	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'support_strike';
	Template.WeaponTech = 'conventional';
	Template.strImage = "img:///UILibrary_Common.AlienWeapons.ArchonStaff";

	Template.RangeAccuracy = class'X2Item_DefaultWeapons'.default.FLAT_CONVENTIONAL_RANGE;
	Template.BaseDamage = default.StrafingRun_A10_T1_BaseDamage;
	Template.iClipSize = default.StrafingRun_A10_T1_Quanitity;
	Template.iSoundRange = 0;
	Template.iEnvironmentDamage = default.StrafingRun_A10_T1_EnvDamage;
	Template.iRadius = default.StrafingRun_A10_T1_Radius;
	Template.iRange = 9999;
	Template.iPhysicsImpulse = 5;
//	Template.DamageTypeTemplateName = 'NoFireExplosion';

	Template.InventorySlot = eInvSlot_Utility;
	Template.Abilities.AddItem('Ability_Support_Air_Off_StrafingRun_Stage1_SelectLocation');

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