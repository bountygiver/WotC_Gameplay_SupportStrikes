//
// FILE:	X2Effect_SmokeMortar
// AUTHOR:	E3245, Iridar
// DESC:	Advanced Smoke Detector
//			Removes smoke effect on soldiers contextually instead of normally just checking if the soldier is on a tile.
//			This means that once the soldier leaves the smoke clouds, the effect is removed, down to the non-smoked tile.
//			- 11/5/2021: This has been disabled for now, and acts like regular smoke. Not sure when it will be re-enabled.
//

class X2Effect_SmokeMortar extends X2Effect_SmokeGrenade;

var name WorldEffectName;

// Alpha Smoke Params
var int AimBonus;
var bool bAlphaSmokeEffect;
var bool bAimBonusAffectsMelee;

// This will remove effects that are on the unit that's in smoke. Effects with Shooter/Target will be cleansed for both.
// Note: This only works with persistent effects
var array<name>		 EffectsToRemove;

//=====================================================
//
// BEGIN EVENT LISTENERS
//
//=====================================================

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
    local X2EventManager        EventMgr;
    local XComGameState_Unit    UnitState;
    local Object                EffectObj;
    local XComGameStateHistory  History;

	// Do not register if the Alpha Smoke effect is enabled.
	if (default.bAlphaSmokeEffect)
		return;
 
    History = `XCOMHISTORY;
    EffectObj = EffectGameState;
 
    //  Unit State of unit in smoke
    UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
 
	if (UnitState != none)
	{
		EventMgr = `XEVENTMGR;
 
		//  EventMgr.RegisterForEvent(EffectObj, 'EventID', EventFn, Deferral, Priority, PreFilterObject,, CallbackData);
		//  EffectObj - Effect State of this particular effect.
		//  PreFilterObject - only listen to Events triggered by this object. Typically, UnitState of the unit this effect was applied to.
		//  CallbackData - any arbitrary object you want to pass along to EventFn. Often it is the Effect State so you can access its ApplyEffectParameters in the EventFn.
 
		//  When this Event is triggered (somewhere inside this Effect), the game will display the Flyover of the ability that has applied this effect.
		EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', CleanseSmokeEffectListener, ELD_Immediate,, UnitState,, EffectGameState);
		EventMgr.RegisterForEvent(EffectObj, 'UnitMoveFinished', CleanseSmokeEffectListener_MoveFinished, ELD_Immediate,, UnitState,, EffectGameState);

		`LOG("[X2Effect_SmokeMortar::" $ GetFuncName() $ "] SUCCESS, Unit State found and registered for AbilityActivated and UnitMoveFinished! ObjectID:" @ UnitState.ObjectID $ " Name: " $ UnitState.GetFullName() $ " of " $ UnitState.GetMyTemplate().strCharacterName ,, 'WotC_Gameplay_SupportStrikes');
    }
    else `LOG("[X2Effect_SmokeMortar::" $ GetFuncName() $ "] ERROR, Could not find UnitState of Object ID: " $ EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID $ "!",, 'WotC_Gameplay_SupportStrikes');
}

static function EventListenerReturn CleanseSmokeEffectListener(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability  AbilityContext;
    local XComGameState_Ability         AbilityState;
    local XComGameState_Unit            UnitState;
	local XComWorldData					WorldData;
	local XComGameState_Effect          EffectState;
	local TTile							Tile;
	local int i;

    //    AbilityState of the ability that was just activated.
    AbilityState = XComGameState_Ability(EventData);
	//    Unit that activated the ability.
    UnitState = XComGameState_Unit(EventSource);
    AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());

	EffectState = XComGameState_Effect(CallbackData);

	if (EffectState == none)
		EffectState = UnitState.GetUnitAffectedByEffectState(default.EffectName);

	if (AbilityState == none || UnitState == none || AbilityContext == none || EffectState == none)
    {
        //    Something went wrong, exit listener.
        return ELR_NoInterrupt;
    }
	
	`LOG("[X2Effect_SmokeMortar::" $ GetFuncName() $ "] Move ability activated by the unit:" @ UnitState.GetFullName(),, 'WotC_Gameplay_SupportStrikes');

	WorldData = `XWORLD;
	
	//	Interrupt stage, before the ability has actually gone through
	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		if (AbilityContext.InputContext.MovementPaths.Length > 0)
		{
			for (i = 0; i < AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length; i++)
			{
				Tile = AbilityContext.InputContext.MovementPaths[0].MovementTiles[i];

				if (!WorldData.TileContainsWorldEffect(Tile, X2Effect_SmokeMortar(EffectState.GetX2Effect()).WorldEffectName))
				{
					`LOG("[X2Effect_SmokeMortar::" $ GetFuncName() $ "] Path takes the unit" @ UnitState.GetFullName() @ "outside Smoke on tile #: " @ i @ ", removing effect.",, 'WotC_Gameplay_SupportStrikes');

					EffectState.RemoveEffect(NewGameState, NewGameState, true);
					return ELR_NoInterrupt;
				}
				`LOG("[X2Effect_SmokeMortar::" $ GetFuncName() $ "] Path DOES NOT take the unit" @ UnitState.GetFullName() @ "outside Smoke. NOT removing effect.",, 'WotC_Gameplay_SupportStrikes');
			}
		}
	}
	else
	{
		// Not in the interrupt stage, ability has been successfully activated.
		//	Move the working code here, if necessary.
	}

	
    return ELR_NoInterrupt;
}


// Cleaned up the function a bit for better readability
// Basically removes the effect if the unit moves to a tile that isn't affected by our custom smoke effect
static function EventListenerReturn CleanseSmokeEffectListener_MoveFinished(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackData)
{
    local XComGameState_Unit            UnitInSmoke;
    local XComGameState_Effect          EffectState;

    //    Unit that finished moving.
	UnitInSmoke = XComGameState_Unit(EventSource);

	// Don't process if the unit is invalid
	if (UnitInSmoke == none)
		return ELR_NoInterrupt;

	// Retrieve the current version from the GS
	//UnitInSmoke = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));

    `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished:" @ UnitInSmoke.GetFullName(),, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

	EffectState = XComGameState_Effect(CallbackData);

	// Retrieve it from the Unit itself
	if (EffectState == none || EffectState.bRemoved)
		EffectState = UnitInSmoke.GetUnitAffectedByEffectState(default.EffectName);
	
	// Don't process if invalid or already removed
	if (EffectState == none || EffectState.bRemoved)
	    return ELR_NoInterrupt;

	// Test if the unit is the one that recently moved, exit if it's mismatched
	if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != UnitInSmoke.ObjectID)
	    return ELR_NoInterrupt;

	// Test if the unit is in the custom smoke tile
	if (!UnitInSmoke.IsInWorldEffectTile(X2Effect_SmokeMortar(EffectState.GetX2Effect()).WorldEffectName) )
    {    
        `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: unit is not in smoke, removing effect",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

        EffectState.RemoveEffect(NewGameState, NewGameState, true);
    } 
    else 
		`LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: unit is on a smoked tile.",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

    return ELR_NoInterrupt;
}

//=====================================================
//
// END EVENT LISTENERS
//
//=====================================================

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
    local XComGameState_Unit            UnitInSmoke;
    local XComGameState_Effect          SuppressionEffectState;

	UnitInSmoke = XComGameState_Unit(kNewTargetState);

	// Clear any reserved action points
	UnitInSmoke.ReserveActionPoints.Length = 0;              //  remove overwatch et. al

	RemoveEffectStates(NewGameState, UnitInSmoke);

	// Apply effect as normal
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function RemoveEffectStates(XComGameState NewGameState, XComGameState_Unit UnitInSmoke)
{
	local name					EffectNameToRemove;
	local XComGameState_Effect	EffectStateToRemove;

	foreach EffectsToRemove(EffectNameToRemove)
	{
		EffectStateToRemove.RemoveEffect(NewGameState, NewGameState);
		break;
	}
}
/*

	Effect changes the chance to hit on itself that's given the effect

*/
function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (Target.IsInWorldEffectTile(WorldEffectName))
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Value = HitMod;
		ShotMod.Reason = FriendlyName;
		ShotModifiers.AddItem(ShotMod);
	}
}

/*

	Effect changes the chance to hit to target

*/
function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotInfo;

	if (bAlphaSmokeEffect && Attacker.IsInWorldEffectTile(WorldEffectName))
	{
		if ( (bAimBonusAffectsMelee && bMelee) || (!bMelee) )
		{
			ShotInfo.ModType = eHit_Success;
			ShotInfo.Value = AimBonus;
			ShotInfo.Reason = FriendlyName;
			ShotModifiers.AddItem(ShotInfo);
		}
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	return TargetUnit.IsInWorldEffectTile(WorldEffectName);
}

static function SmokeGrenadeVisualizationTickedOrRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_UpdateUI UpdateUIAction;

	UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	UpdateUIAction.SpecificID = ActionMetadata.StateObject_NewState.ObjectID;
	UpdateUIAction.UpdateType = EUIUT_UnitFlag_Buffs;
}


DefaultProperties
{
	EffectName = "SmokeMortar"
	DuplicateResponse = eDupe_Allow
	EffectTickedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
	EffectRemovedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
	WorldEffectName = "X2Effect_ApplySmokeMortarToWorld"
}