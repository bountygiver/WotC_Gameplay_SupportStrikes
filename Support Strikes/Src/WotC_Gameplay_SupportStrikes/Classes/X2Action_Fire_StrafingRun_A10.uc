//-----------------------------------------------------------
// Copy of X2Action_BlazingPinionsStage2 with some minor modifications
//-----------------------------------------------------------
class X2Action_Fire_StrafingRun_A10 extends X2Action_Fire config(GameData);

// Exclusive struct for this class
struct ProjectileHitTimer
{
	var vector 	Location;
	var float 	Timer;
};

var config string					ProjectileLoopingFireSound;
var config float 					WaveSpeed;
var config int						NumOfProjectiles;

var Array<int> 						ObjectIDsForTimer;
var Array<float> 					TimersOrder;

var array<ProjectileHitTimer>		ProjectileHitOrder;

var float 							WaveTime;

var int 							OffsetX;
var int 							OffsetY;

var SoundCue 						SFX;

// Fill this out so that the wait action can delay it by this number
var float TimeToImpact;

//Cached info for the unit performing the action
//*************************************
var private CustomAnimParams Params;
var private AnimNotify_FireWeaponVolley FireWeaponNotify;

var private bool	bAllNotifiesReceived;
var XGWeapon		UseWeapon;
var XComWeapon		PreviousWeapon;
//*************************************

function Init()
{
	local float Idx, DistanceToActor, Point;
	local int i;
	local vector PreviousVect, NextVect;
	
	super.Init();
	
	TimeoutSeconds = 15.0f;
	NotifyTargetTimer = 3.0f;
	
	if( AbilityContext.InputContext.ItemObject.ObjectID > 0 )
	{
		UseWeapon = XGWeapon(`XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.ItemObject.ObjectID ).GetVisualizer());

		if (UseWeapon == none)
			`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] WARNING! Invalid Weapon Actor!",, 'WotC_Gameplay_SupportStrikes');
	}	

	//Play sound first before the actual loop
	SFX = SoundCue(`CONTENT.RequestGameArchetype(ProjectileLoopingFireSound));

	// Calculate the distance between the final point and the inital
	DistanceToActor = VSize2D(AbilityContext.InputContext.TargetLocations[0] - UnitPawn.Location);

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Start Location: [" $ UnitPawn.Location.X $ ", "  $ UnitPawn.Location.Y $ ", " $ UnitPawn.Location.Z $ "], End Location: [" $ AbilityContext.InputContext.TargetLocations[0].X $ ", "  $ AbilityContext.InputContext.TargetLocations[0].Y $ ", " $ AbilityContext.InputContext.TargetLocations[0].Z $ "]",, 'WotC_Gameplay_SupportStrikes');

	// Generate vectors that will become our hit points using Linear Interpolation
	for (i = 0; i < NumOfProjectiles + 1; ++i)
	{
		Point = float(i) / float(NumOfProjectiles);
		
		NextVect = VLerp(UnitPawn.Location, AbilityContext.InputContext.TargetLocations[0], Point);

		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Point: " $ Point $ " New Vector [" $ NextVect.X $ ", "  $ NextVect.Y $ ", " $ NextVect.Z $ "]",, 'WotC_Gameplay_SupportStrikes');
		
		AddProjectileHitTimer(NextVect);
	}

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Generated " $ ProjectileHitOrder.Length $ " Impact Locations for Ability: " $ AbilityContext.InputContext.AbilityTemplateName,, 'WotC_Gameplay_SupportStrikes');
}

function AddProjectileHitTimer(Vector TestLocation)
{
	local float DistanceToActor;
	local float TimerDuration, IterDuration;
	local int TimerIndex;
	local bool Placed;
	local ProjectileHitTimer	NewHitOrder, CurrentHitOrder;

	DistanceToActor = VSize2D(TestLocation - UnitPawn.Location);
	TimerDuration = DistanceToActor / WaveSpeed;
	Placed = false;

	// Build the hit order
	NewHitOrder.Location 	= TestLocation;
	NewHitOrder.Timer 		= TimerDuration;

	foreach ProjectileHitOrder(CurrentHitOrder, TimerIndex)
	{
		if( TimerDuration < CurrentHitOrder.Timer )
		{
			ProjectileHitOrder.InsertItem(TimerIndex, NewHitOrder);
			Placed = true;
			break;
		}	
	}

	if( !Placed )
	{
		ProjectileHitOrder.AddItem(NewHitOrder);
	}
}

function CreateProjectile(vector CalcImpactLocation)
{
	local TTile SourceTile;
	local XComWorldData World;
	local vector SourceLocation, ImpactLocation;
	local int ZValue;

	World = `XWORLD;

	// Move it above the top level of the world a bit with *2
	ZValue = World.WORLD_FloorHeightsPerLevel * World.WORLD_TotalLevels * 2;

	// Unfortunately there's only a single used tile, the center
	
	ImpactLocation = CalcImpactLocation;

	// Apply an apt offset
//	ImpactLocation.X += World.WORLD_StepSize * `SYNC_RAND(-2 * 96, 2 * 96);
//	ImpactLocation.Y += World.WORLD_StepSize * `SYNC_RAND(-2 * 96, 2 * 96);

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

		`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Spawning projectile: " $ PathName(WeaponEntity.DefaultProjectileTemplate),, 'WotC_Gameplay_SupportStrikes');

		NewProjectile = class'WorldInfo'.static.GetWorldInfo().Spawn(class'X2UnifiedProjectile', , , , , WeaponEntity.DefaultProjectileTemplate);
		NewProjectile.ConfigureNewProjectileCosmetic(FireVolleyNotify, AbilityContext, , , self, SourceLocation, TargetLocation, true);
		NewProjectile.GotoState('Executing');

		ProjectileVolleys.AddItem(NewProjectile);
	}
}

function float GetDelayModifier()
{
	// No delay
	return 0.0f;
}

// Unhide the FOW
function AddFOWViewer()
{
	FOWViewer = `XWORLD.CreateFOWViewer(UnitPawn.Location, class'XComWorldData'.const.WORLD_StepSize * 5);
}

function CompleteAction()
{
	super.CompleteAction();

	`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] Completing X2Action" ,, 'WotC_Gameplay_SupportStrikes');
}

simulated state Executing
{
	simulated function BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);

		if (SFX != none && SFX.IsA('SoundCue'))
			PlaySound(SFX, true, , , AbilityContext.InputContext.TargetLocations[0]);

		AddFOWViewer();
		WaveTime = 0;	// Reset wave time
	}

	simulated event Tick(float fDeltaT)
	{
		local int ScanTimers;

		super.Tick(fDeltaT);

		WaveTime += fDeltaT;
		for( ScanTimers = 0; ScanTimers < ProjectileHitOrder.Length; ScanTimers++ )
		{
			if( WaveTime >= ProjectileHitOrder[ScanTimers].Timer )
			{
				CreateProjectile(ProjectileHitOrder[ScanTimers].Location);
				ProjectileHitOrder.Remove(ScanTimers, 1);	// Remove this index from the array
				ScanTimers -= 1;

				`LOG("[" $ self.class $ "::" $ GetFuncName() $ "] " $ ProjectileHitOrder.Length $ " left!" ,, 'WotC_Gameplay_SupportStrikes');
			}
			else
			{
				break;
			}
		}
	}
Begin:
	// The tick function will handle most of the legwork, just sleep until we're out of projectiles
	while (ProjectileHitOrder.Length > 0 && !IsTimedOut())
	{
		Sleep(0.0);
	}

	// Notify all targets that this ability is done
	NotifyTargetsAbilityApplied();

	CompleteAction();
}

DefaultProperties
{	
	OutputEventIDs.Add( "Visualizer_AbilityHit"	)		//Signal sent when the target of this shot should react
	OutputEventIDs.Add( "Visualizer_ProjectileHit" )		//Signal sent each time traveling projectiles associated with this action should interact with the environment
	OutputEventIDs.Add( "Visualizer_WorldDamage" )		//Projectiles can directly cause world damage (X2Actoin_ApplyWeaponDamageToTerrain)
	NotifyTargetTimer = 0.75;
	bNotifyMultiTargetsAtOnce = true
}
