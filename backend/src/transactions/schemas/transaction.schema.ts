import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type TransactionRecordDocument = HydratedDocument<TransactionRecord>;

@Schema({ timestamps: true })
export class TransactionRecord {
  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ required: true, trim: true })
  status!: string;

  @Prop({ required: true, trim: true })
  date!: string;

  @Prop({ required: true, trim: true })
  price!: string;

  @Prop({ required: true, trim: true })
  detail!: string;

  @Prop({ required: true, trim: true })
  type!: string;

  @Prop({ required: false, trim: true })
  image?: string;

  @Prop({ required: false, trim: true })
  sellerName?: string;

  @Prop({ required: false, trim: true, lowercase: true })
  sellerEmail?: string;

  @Prop({ required: false, trim: true })
  buyerName?: string;

  @Prop({ required: false, trim: true, lowercase: true })
  buyerEmail?: string;

  @Prop({ required: false, trim: true })
  threadId?: string;
}

export const TransactionRecordSchema = SchemaFactory.createForClass(TransactionRecord);
