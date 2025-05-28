/**
 * JWT Utilities for pgjwt Extension
 * 
 * Implements JWT validation and service role authentication patterns
 * as required by prompt 4.4 for supporting service role authentication
 */

const jwt = require('jsonwebtoken');
const { supabase } = require('./index');

/**
 * Verify pgjwt extension is available in Supabase instance
 */
async function verifyPgjwtExtension() {
    try {
        // Check if pgjwt extension is installed
        const { data, error } = await supabase
            .rpc('check_extension_exists', { extension_name: 'pgjwt' });

        if (error) {
            console.warn('Could not verify pgjwt extension:', error.message);
            return false;
        }

        console.log('pgjwt extension verification:', data ? 'Available' : 'Not available');
        return data;

    } catch (error) {
        console.error('Error verifying pgjwt extension:', error);
        return false;
    }
}

/**
 * Create helper function for JWT validation in database
 * This would be executed as a SQL function in Supabase
 */
const createJwtValidationFunction = `
-- Helper function for service role JWT validation
-- This function would be created in the Supabase database

CREATE OR REPLACE FUNCTION validate_service_role_jwt(token text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    jwt_secret text;
    jwt_payload json;
    jwt_role text;
BEGIN
    -- Get JWT secret from environment (this would be configured in Supabase)
    jwt_secret := current_setting('app.jwt_secret', true);
    
    IF jwt_secret IS NULL THEN
        RAISE EXCEPTION 'JWT secret not configured';
    END IF;
    
    -- Verify and decode JWT using pgjwt extension
    BEGIN
        SELECT payload INTO jwt_payload
        FROM jwt.verify(token, jwt_secret);
    EXCEPTION WHEN OTHERS THEN
        RETURN false;
    END;
    
    -- Extract role from JWT payload
    jwt_role := jwt_payload->>'role';
    
    -- Validate that the role is service_role
    RETURN jwt_role = 'service_role';
END;
$$;

-- Helper function to check if extension exists
CREATE OR REPLACE FUNCTION check_extension_exists(extension_name text)
RETURNS boolean
LANGUAGE sql
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM pg_extension 
        WHERE extname = extension_name
    );
$$;
`;

/**
 * Generate service role JWT token
 * Used for testing and validation purposes
 */
function generateServiceRoleJWT(secret, expiresIn = '1h') {
    const payload = {
        role: 'service_role',
        iss: 'supabase',
        aud: 'authenticated',
        exp: Math.floor(Date.now() / 1000) + (60 * 60), // 1 hour from now
        iat: Math.floor(Date.now() / 1000)
    };

    return jwt.sign(payload, secret, { algorithm: 'HS256' });
}

/**
 * Validate JWT token structure and claims
 */
function validateJWTStructure(token) {
    try {
        // Decode without verification to check structure
        const decoded = jwt.decode(token, { complete: true });

        if (!decoded) {
            return {
                isValid: false,
                error: 'Invalid JWT format'
            };
        }

        const { header, payload } = decoded;

        // Check required header fields
        if (!header.alg || !header.typ) {
            return {
                isValid: false,
                error: 'Missing required JWT header fields'
            };
        }

        // Check required payload fields
        const requiredFields = ['role', 'iss', 'aud'];
        const missingFields = requiredFields.filter(field => !payload[field]);

        if (missingFields.length > 0) {
            return {
                isValid: false,
                error: `Missing required JWT payload fields: ${missingFields.join(', ')}`
            };
        }

        // Check if token is expired
        if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
            return {
                isValid: false,
                error: 'JWT token has expired'
            };
        }

        return {
            isValid: true,
            payload,
            header
        };

    } catch (error) {
        return {
            isValid: false,
            error: `JWT validation error: ${error.message}`
        };
    }
}

/**
 * Verify service role JWT token
 */
function verifyServiceRoleJWT(token, secret) {
    try {
        // First check structure
        const structureCheck = validateJWTStructure(token);
        if (!structureCheck.isValid) {
            return structureCheck;
        }

        // Verify signature and decode
        const decoded = jwt.verify(token, secret, { algorithms: ['HS256'] });

        // Check if role is service_role
        if (decoded.role !== 'service_role') {
            return {
                isValid: false,
                error: `Invalid role: expected 'service_role', got '${decoded.role}'`
            };
        }

        return {
            isValid: true,
            payload: decoded
        };

    } catch (error) {
        return {
            isValid: false,
            error: `JWT verification failed: ${error.message}`
        };
    }
}

/**
 * Extract and validate JWT from Authorization header
 */
function extractJWTFromHeader(authHeader) {
    if (!authHeader) {
        return {
            isValid: false,
            error: 'Missing Authorization header'
        };
    }

    const parts = authHeader.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
        return {
            isValid: false,
            error: 'Invalid Authorization header format. Expected: Bearer <token>'
        };
    }

    return {
        isValid: true,
        token: parts[1]
    };
}

/**
 * Middleware for service role authentication
 */
function authenticateServiceRole(req, res, next) {
    try {
        // Extract JWT from Authorization header
        const headerResult = extractJWTFromHeader(req.headers.authorization);
        if (!headerResult.isValid) {
            return res.status(401).json({
                error: 'Authentication failed',
                message: headerResult.error
            });
        }

        // Verify JWT token
        const jwtSecret = process.env.SUPABASE_JWT_SECRET || process.env.SUPABASE_SERVICE_ROLE_KEY;
        const verificationResult = verifyServiceRoleJWT(headerResult.token, jwtSecret);

        if (!verificationResult.isValid) {
            return res.status(401).json({
                error: 'Authentication failed',
                message: verificationResult.error
            });
        }

        // Add JWT payload to request for downstream use
        req.jwt = verificationResult.payload;
        req.isServiceRole = true;

        next();

    } catch (error) {
        console.error('Service role authentication error:', error);
        res.status(500).json({
            error: 'Authentication error',
            message: 'Internal server error during authentication'
        });
    }
}

/**
 * Test JWT generation and validation flows
 */
function testJWTFlows() {
    const testSecret = 'test-secret-key-for-validation';
    const results = [];

    try {
        // Test 1: Generate valid service role JWT
        const validToken = generateServiceRoleJWT(testSecret);
        const validationResult = verifyServiceRoleJWT(validToken, testSecret);

        results.push({
            test: 'Valid service role JWT',
            success: validationResult.isValid,
            token: validToken.substring(0, 20) + '...',
            result: validationResult
        });

        // Test 2: Test invalid role JWT
        const invalidRolePayload = {
            role: 'authenticated',
            iss: 'supabase',
            aud: 'authenticated'
        };
        const invalidRoleToken = jwt.sign(invalidRolePayload, testSecret);
        const invalidRoleResult = verifyServiceRoleJWT(invalidRoleToken, testSecret);

        results.push({
            test: 'Invalid role JWT (should fail)',
            success: !invalidRoleResult.isValid,
            result: invalidRoleResult
        });

        // Test 3: Test expired JWT
        const expiredPayload = {
            role: 'service_role',
            iss: 'supabase',
            aud: 'authenticated',
            exp: Math.floor(Date.now() / 1000) - 3600 // 1 hour ago
        };
        const expiredToken = jwt.sign(expiredPayload, testSecret);
        const expiredResult = verifyServiceRoleJWT(expiredToken, testSecret);

        results.push({
            test: 'Expired JWT (should fail)',
            success: !expiredResult.isValid,
            result: expiredResult
        });

        // Test 4: Test malformed JWT
        const malformedResult = verifyServiceRoleJWT('invalid.jwt.token', testSecret);

        results.push({
            test: 'Malformed JWT (should fail)',
            success: !malformedResult.isValid,
            result: malformedResult
        });

    } catch (error) {
        results.push({
            test: 'JWT test suite',
            success: false,
            error: error.message
        });
    }

    return results;
}

module.exports = {
    verifyPgjwtExtension,
    createJwtValidationFunction,
    generateServiceRoleJWT,
    validateJWTStructure,
    verifyServiceRoleJWT,
    extractJWTFromHeader,
    authenticateServiceRole,
    testJWTFlows
}; 