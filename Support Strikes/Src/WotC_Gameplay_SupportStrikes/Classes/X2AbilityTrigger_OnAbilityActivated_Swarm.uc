//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTrigger_OnAbilityActivated_Swarm.uc
//  AUTHOR:  E3245
//  DESC:	 Repurposed Ability Activated trigger for an array of specific abilities
//           
//---------------------------------------------------------------------------------------
class X2AbilityTrigger_OnAbilityActivated_Swarm extends X2AbilityTrigger_OnAbilityActivated
	config(GameCore);

var config array<name> AbilityTriggers_Swarm;

simulated function bool OnAbilityActivated(XComGameState_Ability EventAbility, XComGameState GameState, XComGameState_Ability TriggerAbility, Name InEventID)
{
	local GameRulesCache_Unit UnitCache;
	local int i, j;

	if (EventAbility.GetMyTemplateName() == MatchAbilityActivated)
	{
		if (`TACTICALRULES.GetGameRulesCache_Unit(TriggerAbility.OwnerStateObject, UnitCache))
		{
			for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
			{
				if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == TriggerAbility.ObjectID
					&& UnitCache.AvailableActions[i].AvailableTargets.Length > 0)
				{
					for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; ++j)
					{
						class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j);
					}
					break;
				}
			}
		}
		return true;
	}
	return false;
}

function bool AbilityCanTriggerEvent(XComGameState_Ability EventAbility, XComGameState GameState)
{
	local name ExclusionName;

	foreach AbilityTriggers_Swarm(ExclusionName)
	{
		if( EventAbility.GetMyTemplateName() == ExclusionName )
		{
			return false;
		}
	}

	return true;

}