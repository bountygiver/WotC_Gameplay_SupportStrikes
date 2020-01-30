//-----------------------------------------------------------
// Copy of X2Action_BlazingPinionsStage2 with some minor modifications
//-----------------------------------------------------------
class X2Action_MortarStrikeStageTwo extends X2Action_Fire config(GameData);

var config array<float> ProjectileTimeDelaySecArray;
var config string		ProjectileFireSound;

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


	Unit.AddBlazingPinionsProjectile(SourceLocation, ImpactLocation, AbilityContext);

//		`SHAPEMGR.DrawSphere(SourceLocation, vect(15,15,15), MakeLinearColor(0,0,1,1), true);
//		`SHAPEMGR.DrawSphere(ImpactLocation, vect(15,15,15), MakeLinearColor(0,0,1,1), true);
}

simulated state Executing
{
Begin:
	PreviousWeapon = XComWeapon(UnitPawn.Weapon);
	UnitPawn.SetCurrentWeapon(XComWeapon(UseWeapon.m_kEntity));

	Unit.CurrentFireAction = self;

	Offset = `SYNC_RAND(10 , 12);

	for( TimeDelayIndex = 0; TimeDelayIndex < ProjectileTimeDelaySecArray.Length; ++TimeDelayIndex )
	{
		//Play sound first before sleeping
		SFX = `CONTENT.RequestGameArchetype(ProjectileFireSound);

		if (SFX != none && SFX.IsA('SoundCue'))
			PlaySound(SoundCue(SFX), true, , , AbilityContext.InputContext.TargetLocations[TimeDelayIndex]);

		//Sleep before firing next projectile
		Sleep(ProjectileTimeDelaySecArray[TimeDelayIndex] + GetDelayModifier());

		AddProjectiles(TimeDelayIndex, Offset);
	}

	while (!ProjectileHit)
	{
		Sleep(0.01f);
	}

	UnitPawn.SetCurrentWeapon(PreviousWeapon);

//	Sleep(0.5f * GetDelayModifier()); // Sleep to allow destruction to be seen
	Sleep(0.5f);

	CompleteAction();
}

function float GetDelayModifier()
{
//	Commented out until I figure out a way for it to play nice with Zip mode
//	if( ShouldPlayZipMode() || ZombieMode() )
//		return class'X2TacticalGameRuleset'.default.ZipModeDelayModifier;
//	else
		return `SYNC_FRAND(-.2, .3);
}