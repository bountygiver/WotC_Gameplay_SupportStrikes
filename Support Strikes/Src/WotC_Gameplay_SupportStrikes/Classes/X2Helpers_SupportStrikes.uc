class X2Helpers_SupportStrikes extends Object
	config(GameCore);

struct DLCAnimSetAdditions
{
	var Name CharacterTemplate;
	var String AnimSet;
	var String FemaleAnimSet;
};

var config Array<DLCAnimSetAdditions> AnimSetAdditions;

var config array<name>					AppendSupportStrikesCinematicToUnits;
var config array<name>					DetectMovement_EffectImmunities;		//If the target unit we're spotting has these effects, do not trigger!

static function OnPostCharacterTemplatesCreated()
{
	local X2CharacterTemplateManager CharacterTemplateMgr;
	local X2CharacterTemplate SoldierTemplate;
	local array<X2DataTemplate> DataTemplates;
	local int ScanTemplates, ScanAdditions;

	CharacterTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	
	for ( ScanAdditions = 0; ScanAdditions < default.AnimSetAdditions.Length; ++ScanAdditions )
	{
		CharacterTemplateMgr.FindDataTemplateAllDifficulties(default.AnimSetAdditions[ScanAdditions].CharacterTemplate, DataTemplates);
		for ( ScanTemplates = 0; ScanTemplates < DataTemplates.Length; ++ScanTemplates )
		{
			SoldierTemplate = X2CharacterTemplate(DataTemplates[ScanTemplates]);
			if (SoldierTemplate != none)
			{
				SoldierTemplate.AdditionalAnimSets.AddItem(AnimSet(`CONTENT.RequestGameArchetype(default.AnimSetAdditions[ScanAdditions].AnimSet)));
				SoldierTemplate.AdditionalAnimSetsFemale.AddItem(AnimSet(`CONTENT.RequestGameArchetype(default.AnimSetAdditions[ScanAdditions].FemaleAnimSet)));

				//Append any Cinematic maps into the soldiers as well
				//SoldierTemplate.strMatineePackages.AddItem("CIN_Vehicle_Aircraft_A10");
			}
		}
	}
}

static function OnPostAbilityTemplatesCreated()
{
	local X2AbilityTemplateManager				AbilityMgr;
	local array<X2AbilityTemplate>				TemplateAllDifficulties;
	local array<name>							AblilityTemplateNames;
	local name							        IterName;
	local X2AbilityTemplate						AbilityTemplate;

	local name 									EffectImmunities;
	local X2Condition_UnitEffects				UnitEffects;
	
	local X2Condition							Condition;
	local X2Condition_UnitEffects				UnitEffectCondition;
	local bool									bEffectFound;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	//AbilityMgr.GetTemplateNames(AblilityTemplateNames);

	AblilityTemplateNames.AddItem('DetectMovingUnit');

	foreach AblilityTemplateNames(IterName)
	{
 		AbilityMgr.FindAbilityTemplateAllDifficulties(IterName, TemplateAllDifficulties);
		foreach TemplateAllDifficulties(AbilityTemplate)
		{
			switch (IterName)
			{
				case 'DetectMovingUnit':
					UnitEffects = new class'X2Condition_UnitEffects';
					
					foreach	default.DetectMovement_EffectImmunities(EffectImmunities)
					{
						UnitEffects.AddExcludeEffect(EffectImmunities, 'AA_UnitIsImmune');
					}

					AbilityTemplate.AbilityTargetConditions.AddItem(UnitEffects);
					break;
				default:
					break;
			}

			// Disable abilities if a unit is in smoke
			if (class'X2Ability_MortarStrikes'.default.MortarStrike_SMK_EnableAlphaSmokeEffect &&
				class'X2Ability_MortarStrikes'.default.MortarStrike_SMK_AbilitiesToDisableWhileInSmoke.Find(IterName) != INDEX_NONE)
			{
				bEffectFound = false;

				foreach AbilityTemplate.AbilityShooterConditions(Condition)
				{
					UnitEffectCondition = X2Condition_UnitEffects(Condition);

					// Only the first one is valid
					if ( UnitEffectCondition != none )
					{
						UnitEffectCondition.AddExcludeEffect(class'X2Effect_SmokeMortar'.default.EffectName, 'AA_AbilityUnavailable');
						bEffectFound = true;
						break;
					}
				}

				if (!bEffectFound)
				{
					UnitEffectCondition = new class'X2Condition_UnitEffects';
					UnitEffectCondition.AddExcludeEffect(class'X2Effect_SmokeMortar'.default.EffectName, 'AA_AbilityUnavailable');
					AbilityTemplate.AbilityShooterConditions.AddItem(UnitEffectCondition);
				}
			}
        }
    }
}