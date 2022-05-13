//-----------------------------------------------------------
// Copy of X2Action_BlazingPinionsStage2 with some minor modifications
//-----------------------------------------------------------
class X2Action_MortarStrikeStageTwo extends X2Action_Fire config(GameData);

var config array<float> ProjectileTimeDelaySecArray;

var config string		ProjectileFireSound;
var string				OverrideProjectileFireSound;

var int Offset;

var Object SFX;

//Cached info for the unit performing the action
//*************************************
var private CustomAnimParams Params;
var private AnimNotify_FireWeaponVolley FireWeaponNotify;
var private int TimeDelayIndex;

var bool		ProjectileHit;
var XGWeapon	UseWeapon;
var XComWeapon	PreviousWeapon;
var XComUnitPawn FocusUnitPawn;
//*************************************

function Init()
{
	super.Init();

	if( AbilityContext.InputContext.ItemObject.ObjectID > 0 )
	{
		UseWeapon = XGWeapon(`XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.ItemObject.ObjectID ).GetVisualizer());
	}	
}

function bool CheckInterrupted()
{
	return false;
}

function NotifyTargetsAbilityApplied()
{
	super.NotifyTargetsAbilityApplied();
	ProjectileHit = true;
}

function AddProjectiles(int ProjectileIndex, int InputOffset)
{
	local TTile SourceTile;
	local XComWorldData World;
	local vector SourceLocation, ImpactLocation;
	local int ZValue;


	World = `XWORLD;

	// Move it above the top level of the world a bit with *2
	ZValue = World.WORLD_FloorHeightsPerLevel * World.WORLD_TotalLevels * 2;

	ImpactLocation = AbilityContext.InputContext.TargetLocations[ProjectileIndex];

	// Calculate the upper z position for the projectile
	SourceTile = World.GetTileCoordinatesFromPosition(ImpactLocation);
	
	World.GetFloorPositionForTile(SourceTile, ImpactLocation);

	SourceTile.Z = ZValue;
	SourceLocation = World.GetPositionFromTileCoordinates(SourceTile);

	SourceLocation.X += World.WORLD_StepSize * InputOffset;
	SourceLocation.Y += World.WORLD_StepSize * InputOffset;

	AddWeaponCosmeticProjectile(SourceLocation, ImpactLocation, AbilityContext);
}

// External to XComUnitPawnNativeBase.uc. Allows us to spawn in the projectile without the need for a unit
function AddWeaponCosmeticProjectile(vector SourceLocation, vector TargetLocation, XComGameStateContext_Ability AbilityContext)
{
	local XComWeapon WeaponEntity;
	local XComUnitPawn UnitPawn;
	local X2UnifiedProjectile NewProjectile;
	local AnimNotify_FireWeaponVolley FireVolleyNotify;

	//The archetypes for the projectiles come from the weapon entity archetype
	WeaponEntity = XComWeapon(UseWeapon.m_kEntity);

	if( WeaponEntity != none )
	{
		FireVolleyNotify = new class'AnimNotify_FireWeaponVolley';
		FireVolleyNotify.NumShots = 1;
		FireVolleyNotify.ShotInterval = 0.3f;
		FireVolleyNotify.bCosmeticVolley = true;

		NewProjectile = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2UnifiedProjectile', , , , , WeaponEntity.DefaultProjectileTemplate);
		NewProjectile.ConfigureNewProjectileCosmetic(FireVolleyNotify, AbilityContext, , , self, SourceLocation, TargetLocation, true);
		NewProjectile.GotoState('Executing');
	}
}

function PlaySoundCustom(int Index)
{
	local string SFXToPlay;

	SFXToPlay = ProjectileFireSound;

	if (OverrideProjectileFireSound != "")
		SFXToPlay = OverrideProjectileFireSound;

	//Play sound
	SFX = `CONTENT.RequestGameArchetype(SFXToPlay);

	if (SFX != none && SFX.IsA('SoundCue'))
		PlaySound(SoundCue(SFX), true, , , AbilityContext.InputContext.TargetLocations[Index]);
}
function CompleteAction()
{
	EndVolleyConstants( none ); //end everything just to be safe and not leak projectiles that are just hanging around, executing and doing nothing

	if(class'XComTacticalGRI'.static.GetReactionFireSequencer().IsReactionFire(AbilityContext))
	{
		class'XComTacticalGRI'.static.GetReactionFireSequencer().PopReactionFire(AbilityContext);		
	}

	if( !bNotifiedTargets && IsTimedOut() )
	{
		NotifyTargetsAbilityApplied();
	}

	// I bet you never knew about this ;')
	super(X2Action).CompleteAction();
}

function float GetDelayModifier()
{
//	Commented out until I figure out a way for it to play nice with Zip mode
//	if( ShouldPlayZipMode() || ZombieMode() )
//		return class'X2TacticalGameRuleset'.default.ZipModeDelayModifier;
//	else
		return `SYNC_FRAND(-.2, .3);
}

simulated state Executing
{
Begin:
	Offset = `SYNC_RAND(10 , 12);

	for( TimeDelayIndex = 0; TimeDelayIndex < ProjectileTimeDelaySecArray.Length; ++TimeDelayIndex )
	{
		PlaySoundCustom(TimeDelayIndex);

		//Sleep before firing next projectile
		Sleep(ProjectileTimeDelaySecArray[TimeDelayIndex] + GetDelayModifier());

		AddProjectiles(TimeDelayIndex, Offset);
	}

	while (!ProjectileHit)
	{
		Sleep(0.01f);
	}

//	Sleep(0.5f * GetDelayModifier()); // Sleep to allow destruction to be seen
	Sleep(0.5f);

	CompleteAction();
}
