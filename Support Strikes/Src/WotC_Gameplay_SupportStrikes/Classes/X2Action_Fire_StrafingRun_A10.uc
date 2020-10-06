//-----------------------------------------------------------
// Copy of X2Action_BlazingPinionsStage2 with some minor modifications
//-----------------------------------------------------------
class X2Action_Fire_StrafingRun_A10 extends X2Action_Fire config(GameData);

var config array<float> ProjectileTimeDelaySecArray;
var config string		ProjectileLoopingFireSound;

var int OffsetX;
var int OffsetY;

var Object SFX;

// Fill this out so that the wait action can delay it by this number
var float TimeToImpact;

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

function AddProjectiles(int ProjectileIndex, int InputOffsetX, int InputOffsetY)
{
	local TTile SourceTile;
	local XComWorldData World;
	local vector SourceLocation, ImpactLocation;
	local int ZValue;


	World = `XWORLD;

	// Move it above the top level of the world a bit with *2
	ZValue = World.WORLD_FloorHeightsPerLevel * World.WORLD_TotalLevels * 2;

	// Unfortunately there's only a single used tile, the center
	
	ImpactLocation = AbilityContext.InputContext.TargetLocations[0];

	// Apply an apt offset
	ImpactLocation.X += World.WORLD_StepSize * InputOffsetX;
	ImpactLocation.Y += World.WORLD_StepSize * InputOffsetY;

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Impact Location: [" $ ImpactLocation.X $ ", "  $ ImpactLocation.Y $ ", " $ ImpactLocation.Z $ "], Rotation: [" $ 
	Rotator(ImpactLocation).Pitch $ ", "  $ Rotator(ImpactLocation).Yaw $ ", " $ Rotator(ImpactLocation).Roll $ "]" ,, 'WotC_Gameplay_SupportStrikes');


	// Calculate the upper z position for the projectile
	SourceTile = World.GetTileCoordinatesFromPosition(ImpactLocation);
	
	World.GetFloorPositionForTile(SourceTile, ImpactLocation);

	SourceTile.Z = ZValue;
	SourceLocation = World.GetPositionFromTileCoordinates(SourceTile);

	//SourceLocation.X = ImpactLocation.X;
	//SourceLocation.Y = ImpactLocation.Y;
	
	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Source Location: [" $ SourceLocation.X $ ", "  $ SourceLocation.Y $ ", " $ SourceLocation.Z $ "], Rotation: [" $ 
	Rotator(SourceLocation).Pitch $ ", "  $ Rotator(SourceLocation).Yaw $ ", " $ Rotator(SourceLocation).Roll $ "]" ,, 'WotC_Gameplay_SupportStrikes');

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

	//Play sound first before the actual loop
	SFX = `CONTENT.RequestGameArchetype(ProjectileLoopingFireSound);

	if (SFX != none && SFX.IsA('SoundCue'))
		PlaySound(SoundCue(SFX), true, , , AbilityContext.InputContext.TargetLocations[TimeDelayIndex]);

	for( TimeDelayIndex = 0; TimeDelayIndex < ProjectileTimeDelaySecArray.Length; ++TimeDelayIndex )
	{
		OffsetX = `SYNC_RAND(-6 , 6);
		OffsetY = `SYNC_RAND(-6 , 6);

		//Sleep before firing next projectile
		Sleep(ProjectileTimeDelaySecArray[TimeDelayIndex] + GetDelayModifier());

		AddProjectiles(TimeDelayIndex, OffsetX, OffsetY);
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
	// No delay
	return 0.0f;
}