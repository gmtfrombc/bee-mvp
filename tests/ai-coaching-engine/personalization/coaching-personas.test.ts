import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { derivePersona, CoachingPersona, isValidMomentumState, getPersonaDescription } from "../../../functions/ai-coaching-engine/personalization/coaching-personas.ts";
import { PatternSummary } from "../../../functions/ai-coaching-engine/personalization/pattern-analysis.ts";

Deno.test("derivePersona - high volatility gets supportive persona", () => {
    const summary: PatternSummary = {
        engagementPeaks: ['morning', 'evening'],
        volatilityScore: 0.8
    };

    const result = derivePersona(summary, 'Rising');

    assertEquals(result, 'supportive');
});

Deno.test("derivePersona - NeedsCare momentum gets supportive persona", () => {
    const summary: PatternSummary = {
        engagementPeaks: ['afternoon'],
        volatilityScore: 0.2
    };

    const result = derivePersona(summary, 'NeedsCare');

    assertEquals(result, 'supportive');
});

Deno.test("derivePersona - Rising momentum with low volatility gets challenging persona", () => {
    const summary: PatternSummary = {
        engagementPeaks: ['morning'],
        volatilityScore: 0.3
    };

    const result = derivePersona(summary, 'Rising');

    assertEquals(result, 'challenging');
});

Deno.test("derivePersona - Steady momentum with low volatility gets educational persona", () => {
    const summary: PatternSummary = {
        engagementPeaks: ['morning', 'evening'],
        volatilityScore: 0.2
    };

    const result = derivePersona(summary, 'Steady');

    assertEquals(result, 'educational');
});

Deno.test("derivePersona - invalid momentum state defaults to supportive", () => {
    const summary: PatternSummary = {
        engagementPeaks: [],
        volatilityScore: 0.5
    };

    const result = derivePersona(summary, 'InvalidState');

    assertEquals(result, 'supportive');
});

Deno.test("isValidMomentumState - validates momentum states correctly", () => {
    assertEquals(isValidMomentumState('Rising'), true);
    assertEquals(isValidMomentumState('Steady'), true);
    assertEquals(isValidMomentumState('NeedsCare'), true);
    assertEquals(isValidMomentumState('Invalid'), false);
    assertEquals(isValidMomentumState(''), false);
});

Deno.test("getPersonaDescription - returns valid descriptions", () => {
    const supportiveDesc = getPersonaDescription('supportive');
    const challengingDesc = getPersonaDescription('challenging');
    const educationalDesc = getPersonaDescription('educational');

    assertEquals(typeof supportiveDesc, 'string');
    assertEquals(typeof challengingDesc, 'string');
    assertEquals(typeof educationalDesc, 'string');

    assertEquals(supportiveDesc.length > 0, true);
    assertEquals(challengingDesc.length > 0, true);
    assertEquals(educationalDesc.length > 0, true);
}); 