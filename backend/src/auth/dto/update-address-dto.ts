import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateAddressDto {
  @IsOptional()
  @IsString()
  street?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  province?: string;

  @IsOptional()
  @IsString()
  postalCode?: string;

  @IsOptional()
  @IsString()
  rt?: string;

  @IsOptional()
  @IsString()
  rw?: string;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
