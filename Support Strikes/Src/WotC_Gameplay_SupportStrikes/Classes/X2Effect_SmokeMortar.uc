class X2Effect_SmokeMortar extends X2Effect_SmokeGrenade;

var int AimBonus;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
    local X2EventManager        EventMgr;
    local XComGameState_Unit    UnitState;
    local Object                EffectObj;
    local XComGameStateHistory  History;
 
    History = `XCOMHISTORY;
    EffectObj = EffectGameState;
 
    //  Unit State of unit in smoke
    UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
 
	if (UnitState != none)
	{
		EventMgr = `XEVENTMGR;
 
		//  EventMgr.RegisterForEvent(EffectObj, 'EventID', EventFn, Deferral, Priority, PreFilterObject,, CallbackData);
		//  EffectObj - Effect State of this particular effect.
		//  PreFilterObject - only listen to Events triggered by this object. Typically, UnitState of the unit this effect was applied to.
		//  CallbackData - any arbitrary object you want to pass along to EventFn. Often it is the Effect State so you can access its ApplyEffectParameters in the EventFn.
 
		//  When this Event is triggered (somewhere inside this Effect), the game will display the Flyover of the ability that has applied this effect.
		EventMgr.RegisterForEvent(EffectObj, 'ObjectMoved', CleanseSmokeEffectListener, ELD_Immediate,, UnitState,, EffectObj);
		`LOG("Success, Unit State found and registered for ObjectMoved! ObjectID:" @ UnitState.ObjectID $ " Name: " $ UnitState.GetFullName() ,, 'WotC_Gameplay_SupportStrikes');
    
    }
    else `LOG("ERROR, Could not find UnitState!",, 'WotC_Gameplay_SupportStrikes');
}

static function EventListenerReturn CleanseSmokeEffectListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
    local XComGameState_Unit            UnitInSmoke;
    local XComGameState_Effect          EffectState;
    local XComGameState                 NewGameState;

    UnitInSmoke = XComGameState_Unit(EventData);
 
    if (UnitInSmoke != none)
    {
		if ( !UnitInSmoke.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name) )
		{
			EffectState = XComGameState_Effect(CallbackData);
			if (EffectState != none)
			{
			    EffectState.RemoveEffect(NewGameState, NewGameState, true);

			    `LOG("Success, removed smoke effect from Unit " $ UnitInSmoke.GetFullName(),, 'WotC_Gameplay_SupportStrikes');
 
			    return ELR_NoInterrupt;
			}
		}
    }

    `LOG("Error, something went wrong, could not remove the smoke effect. EventID:" @ EventID @ UnitInSmoke == none @ EffectState == none,, 'WotC_Gameplay_SupportStrikes');
 
    return ELR_NoInterrupt;
}
/*

	Effect changes the chance to hit on itself that's given the effect

*/
function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (Target.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name))
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

	if (Target.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name))
	{
		//Only melee is immune to smoke's aim malus
		if (!bMelee)
		{
			ShotInfo.ModType = eHit_Success;
			ShotInfo.Value = AimBonus;
			ShotInfo.Reason = FriendlyName;
			ShotModifiers.AddItem(ShotInfo);

			`LOG("Success, Changed aim bonus for attacker",, 'WotC_Gameplay_SupportStrikes');
 
		}
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	return TargetUnit.IsInWorldEffectTile(class'X2Effect_ApplySmokeMortarToWorld'.default.Class.Name);
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
	DuplicateResponse = eDupe_Refresh
	EffectTickedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
	EffectRemovedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
}