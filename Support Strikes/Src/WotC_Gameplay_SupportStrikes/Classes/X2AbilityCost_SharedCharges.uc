
class X2AbilityCost_SharedCharges extends X2AbilityCost_Charges;

var array<name> AbilitiesToFind;    // This will reduce charges of these abilites, but not this ability
var bool        bIncludeThisAbility;

// We need a custom version of CanAfford to make sure it doesn't error out improperly
simulated function name CanAfford(XComGameState_Ability kAbility, XComGameState_Unit ActivatingUnit)
{
    local XComGameStateHistory      History;
    local array<name>               arrAbilities;
    local XComGameState_Unit        UnitState;
    local ETeam                     FiringUnitTeam;
    local XComGameState_AIGroup     GroupState;
    local StateObjectReference      AbilityRef, ObjRef;
    local XComGameState_Ability     AbilityState;
    local XComGameState_Item        AffectWeapon;
    local name                      AbilityName;

    History = `XCOMHISTORY;

    arrAbilities = AbilitiesToFind;

    if (arrAbilities.Length == 0 || bIncludeThisAbility)
    {
        arrAbilities.AddItem(kAbility.GetMyTemplateName());
    }

    FiringUnitTeam  = ActivatingUnit.GetTeam();
    GroupState      = ActivatingUnit.GetGroupMembership();

    // Break on the first found instance of the ability we're looking for
    foreach GroupState.m_arrMembers(ObjRef)
    {
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjRef.ObjectID));
		
        if (UnitState != None && UnitState.GetTeam() == FiringUnitTeam)
        {
            foreach arrAbilities(AbilityName)
            {
                AbilityRef = UnitState.FindAbility(AbilityName);
                if (AbilityRef.ObjectID > 0)
                {
		            AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

                    // Check if the Item state is also using ammo as charges
                    if (AbilityState.GetMyTemplate().bUseAmmoAsChargesForHUD)
                    {
                        AffectWeapon = AbilityState.GetSourceWeapon();
                        if (AffectWeapon.Ammo - NumCharges > -1)
                            return 'AA_Success';  
                    }
                    else if (AbilityState.iCharges - NumCharges > -1)
                    {
                        return 'AA_Success';  
                    }
                }
            }
        }
    }

    return 'AA_CannotAfford_Charges';
}

simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
    local XComGameStateHistory      History;
    local array<name>               arrAbilities;
    local XComGameState_Unit        UnitState;
    local ETeam                     FiringUnitTeam;
    local XComGameState_AIGroup     GroupState;
    local StateObjectReference      AbilityRef, ObjRef;
    local XComGameState_Ability     AbilityState;
    local name                      AbilityName;

    History = `XCOMHISTORY;

    arrAbilities = AbilitiesToFind;

    if (arrAbilities.Length == 0 || bIncludeThisAbility)
    {
        arrAbilities.AddItem(kAbility.GetMyTemplateName());
    }
    
    UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
    if (UnitState == None)
    {
        UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
    }
    FiringUnitTeam  = UnitState.GetTeam();
    GroupState      = UnitState.GetGroupMembership();  

    foreach GroupState.m_arrMembers(ObjRef)
    {
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjRef.ObjectID));
		
        if (UnitState != None && UnitState.GetTeam() == FiringUnitTeam)
        {
            foreach arrAbilities(AbilityName)
            {
                AbilityRef = UnitState.FindAbility(AbilityName);
                if (AbilityRef.ObjectID > 0)
                {
                    AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', AbilityRef.ObjectID));
                    AbilityState.iCharges -= NumCharges;

                    // Check if the Item state is also using ammo as charges. We need to keep that in sync.
                    if (AbilityState.GetMyTemplate().bUseAmmoAsChargesForHUD)
                    {
                        AffectWeapon = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', AffectWeapon.ObjectID));
                        AffectWeapon.Ammo -= NumCharges;
                    }
                }
            }
        }
    }
}