class X2Condition_AbilityCharges extends X2Condition;

var array<name> AbilityToCheck;
var int MinNumberOfCharges;

function name MeetsCondition(XComGameState_BaseObject kTarget)
{
    local XComGameState_Unit        UnitState;
    local name                      AbilityName;
    local StateObjectReference      AbilityRef;
    local XComGameState_Ability     AbilityState;

    UnitState = XComGameState_Unit(kTarget);

    foreach AbilityToCheck(AbilityName)
    {
        AbilityRef = UnitState.FindAbility(AbilityName);
        if (AbilityRef.ObjectID > 0)
        {
            AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
            
            if (AbilityState.iCharges > MinNumberOfCharges)
            {
                return 'AA_Success';
            }
            // We found the ability but it does not have enough charges
            else
            {
                return 'AA_CannotAfford_Charges'; 
            }
        }
    }

    // Ability does not exist
    return 'AA_UnknownError';
}

defaultproperties
{
    MinNumberOfCharges = 0;
}